#!/usr/bin/env bash
# Wrap the keypop binary in a minimal .app bundle for stable LaunchAgent TCC.
#
# Usage: ./scripts/bundle-keypop-app.sh [path/to/keypop-binary]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_BIN="${1:-${HOME}/.local/bin/keypop}"
APP_ROOT="${HOME}/.local/KeyPop.app"
APP_MACOS="${APP_ROOT}/Contents/MacOS"
APP_PLIST="${APP_ROOT}/Contents/Info.plist"

if [[ ! -x "$SOURCE_BIN" ]]; then
  echo "error: keypop binary not found: $SOURCE_BIN" >&2
  exit 1
fi

mkdir -p "$APP_MACOS"
cp -f "$SOURCE_BIN" "${APP_MACOS}/keypop"
chmod +x "${APP_MACOS}/keypop"

cat >"$APP_PLIST" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>keypop</string>
  <key>CFBundleIdentifier</key><string>io.keypop.app</string>
  <key>CFBundleName</key><string>KeyPop</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.2.0</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign -s - --force --deep "$APP_ROOT" >/dev/null

echo "Bundled: ${APP_MACOS}/keypop"
echo "Grant TCC to: ${APP_ROOT}"
echo "  System Settings → Privacy & Security → Input Monitoring + Accessibility"
echo "  Click +, press Cmd+Shift+G, paste: ${APP_ROOT}"
