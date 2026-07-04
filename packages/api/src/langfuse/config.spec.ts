process.env.CREDS_KEY =
  process.env.CREDS_KEY ?? '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
delete process.env.LANGFUSE_FANOUT_TENANT_EXPORT_DISABLED;

import type { AppConfig } from '@librechat/data-schemas';

// Loaded via dynamic import in beforeAll so the crypto module initializes
// after CREDS_KEY is set above (encryptV3 reads the key at module load).
let encryptV3: typeof import('@librechat/data-schemas').encryptV3;
let buildLangfuseConfig: typeof import('./config').buildLangfuseConfig;

beforeAll(async () => {
  ({ encryptV3 } = await import('@librechat/data-schemas'));
  ({ buildLangfuseConfig } = await import('./config'));
});

const COLLECTOR_URL = 'http://collector:4318';

function appConfig(langfuse: Record<string, unknown>): AppConfig {
  return {
    langfuse: { fanout: { enabled: true, collectorUrl: COLLECTOR_URL }, ...langfuse },
  } as unknown as AppConfig;
}

describe('buildLangfuseConfig tenant secret resolution', () => {
  it('passes a plaintext tenant secret through to the tenant export', () => {
    const result = buildLangfuseConfig({
      appConfig: appConfig({
        publicKey: 'pk-lf',
        secretKey: 'sk-plaintext',
        baseUrl: 'https://cloud.langfuse.com',
      }),
    });

    expect(result.publicKey).toBe('pk-lf');
    expect(result.secretKey).toBe('sk-plaintext');
    expect(result.baseUrl).toBe(`${COLLECTOR_URL}/tenant/eu`);
  });

  it('decrypts a v3-encrypted tenant secret before use', () => {
    const result = buildLangfuseConfig({
      appConfig: appConfig({
        publicKey: 'pk-lf',
        secretKey: encryptV3('sk-encrypted'),
        baseUrl: 'https://cloud.langfuse.com',
      }),
    });

    expect(result.secretKey).toBe('sk-encrypted');
    expect(result.baseUrl).toBe(`${COLLECTOR_URL}/tenant/eu`);
  });

  it('disables tenant export when the encrypted secret cannot be decrypted', () => {
    const result = buildLangfuseConfig({
      appConfig: appConfig({
        publicKey: 'pk-lf',
        secretKey: 'v3:deadbeef:not-decryptable',
        baseUrl: 'https://cloud.langfuse.com',
      }),
    });

    expect(result.secretKey).toBeUndefined();
    expect(result.baseUrl).toBe(COLLECTOR_URL);
  });
});
