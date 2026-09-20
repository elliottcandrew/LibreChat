#!/bin/bash

DIR="$HOME/librechat2"
cd "$DIR" || exit 1

echo "🚀 Starting LibreChat containers..."
docker compose up -d

echo "⏳ Waiting for LibreChat to be ready..."
until curl -s -o /dev/null http://localhost:3080 2>/dev/null; do
  sleep 2
done

echo "✅ Launching LibreChat PWA..."
/usr/bin/firefoxpwa site launch 01M08R9NN9Q99C0CWD6MXX87M1

# Crucial: wait for the Firefox runtime to actually start
sleep 5

PROFILE_DIR="$HOME/.local/share/firefoxpwa/profiles/01M08R9NKBKCJPRANKFQ9SF7ZC"

echo "🔄 LibreChat is running. Close the PWA window to stop."
while pgrep -f "$PROFILE_DIR" >/dev/null 2>&1; do
  sleep 3
done

echo "🛑 LibreChat window closed. Stopping containers..."
docker compose down

echo "✅ Done!"
