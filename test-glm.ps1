# ============================================================
# OpenRouter GLM-5.2 Reasoning Leak Test (PowerShell 5.1)
# ============================================================

$apiKey = $env:OPENROUTER_KEY
if (-not $apiKey) {
    Write-Host "Set OPENROUTER_KEY env var first:" -ForegroundColor Red
    Write-Host '  $env:OPENROUTER_KEY = "sk-or-v1-xxxxx"'
    exit
}

$body = @{
    model    = "z-ai/glm-5.2"
    messages = @(@{ role = "user"; content = "What is 15 times 17? Show your work." })
    reasoning = @{ exclude = $false; max_tokens = 100 }
    stream   = $false
} | ConvertTo-Json -Depth 5

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
}

Write-Host ""
Write-Host "=== GLM-5.2 with exclude: true ===" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" `
        -Method Post -Headers $headers -Body $body
} catch {
    Write-Host "API Error: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# --- reasoning field (text string) ---
$reasoningText = $response.choices[0].message.reasoning
Write-Host ""
Write-Host "[reasoning field] (should be empty/null):" -ForegroundColor Yellow
if ([string]::IsNullOrEmpty($reasoningText)) {
    Write-Host "<EMPTY>"
} else {
    Write-Host $reasoningText
}

# --- reasoning_details field (array - leak suspect) ---
$reasoningDetails = $response.choices[0].message.reasoning_details
Write-Host ""
Write-Host "[reasoning_details field] (LEAK if populated):" -ForegroundColor Yellow
if ($reasoningDetails) {
    $reasoningDetails | ConvertTo-Json -Depth 5
} else {
    Write-Host "<EMPTY - no leak>"
}

# --- content field (actual answer) ---
Write-Host ""
Write-Host "[content field] (the actual answer):" -ForegroundColor Green
Write-Host $response.choices[0].message.content

# --- usage (billing) ---
Write-Host ""
Write-Host "[usage] (check reasoning_tokens billing):" -ForegroundColor Magenta
$response.usage | ConvertTo-Json -Depth 5

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan