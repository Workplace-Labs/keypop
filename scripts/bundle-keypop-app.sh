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
  <key>NSInputMonitoringUsageDescription</key>
  <string>KeyPop listens for text replacement shortcuts (e.g. ;pcr) and expands them in Warp, VS Code, Cursor, and terminals.</string>
  <key>NSAccessibilityUsageDescription</key>
  <string>KeyPop injects expanded text into the active app after you type a shortcut.</string>
</dict>
</plist>
PLIST

# Signing: prefer KEYPOP_SIGNING_IDENTITY, then local "KeyPop Dev" self-signed cert.
# Run ./scripts/create-keypop-signing-cert.sh once. Do not use client Apple Dev certs.
DEFAULT_SIGNING_IDENTITY="KeyPop Dev"

resolve_signing_identity() {
  if [[ -n "${KEYPOP_SIGNING_IDENTITY:-}" ]]; then
    echo "${KEYPOP_SIGNING_IDENTITY}"
    return 0
  fi
  if security find-certificate -c "${DEFAULT_SIGNING_IDENTITY}" -a 2>/dev/null | grep -q "keychain:"; then
    echo "${DEFAULT_SIGNING_IDENTITY}"
    return 0
  fi
  return 1
}

SIGNING_IDENTITY=""
if SIGNING_IDENTITY="$(resolve_signing_identity)"; then
  codesign --force --sign "$SIGNING_IDENTITY" --deep "$APP_ROOT" >/dev/null
  echo "Signed with: ${SIGNING_IDENTITY}"
else
  echo "warning: no KeyPop Dev certificate; using ad-hoc signing (TCC grants break on every rebuild)" >&2
  echo "  Run: ./scripts/create-keypop-signing-cert.sh" >&2
  codesign --force --sign - --deep "$APP_ROOT" >/dev/null
fi

codesign -dv --verbose=2 "$APP_ROOT" 2>&1 | awk -F= '/Authority=|Identifier=|TeamIdentifier=/{print}'

echo "Bundled: ${APP_MACOS}/keypop"
echo "Grant TCC to: ${APP_ROOT}"
echo "  System Settings → Privacy & Security → Input Monitoring"
echo "  System Settings → Privacy & Security → Accessibility"
echo "  Click +, press Cmd+Shift+G, paste: ${APP_ROOT}"
