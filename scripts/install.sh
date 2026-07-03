#!/usr/bin/env bash
# Build keypop and install to ~/.local/bin (or --prefix <dir>).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=keypop-paths.sh
source "${SCRIPT_DIR}/keypop-paths.sh"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_PREFIX="${HOME}/.local/bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      INSTALL_PREFIX="${2:?missing value for --prefix}"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--prefix <directory>]"
      echo "  Builds release keypop binary and installs to <directory>/."
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: requires macOS" >&2
  exit 1
fi

major="$(sw_vers -productVersion | cut -d. -f1)"
if [[ "${major}" -lt 14 ]]; then
  echo "error: macOS 14+ required" >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "error: swift not found. Install Xcode Command Line Tools (not full Xcode):" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

echo "Building release binary..."
swift build --package-path "$PROJECT_DIR" -c release -q

mkdir -p "$INSTALL_PREFIX"
cp "${PROJECT_DIR}/.build/release/keypop" "${INSTALL_PREFIX}/keypop"
chmod +x "${INSTALL_PREFIX}/keypop"
echo "Installed: ${INSTALL_PREFIX}/keypop"

"${PROJECT_DIR}/scripts/bundle-keypop-app.sh" "${INSTALL_PREFIX}/keypop"

if [[ ! -f "${PROJECT_DIR}/assets/AppIcon.icns" ]]; then
  echo "Generating AppIcon.icns..."
  "${PROJECT_DIR}/scripts/generate-app-icon.sh"
fi

if [[ -d "${KEYPOP_APP_LEGACY}" && "${KEYPOP_APP}" != "${KEYPOP_APP_LEGACY}" ]]; then
  echo ""
  echo "App moved to ${KEYPOP_APP}. Re-grant Input Monitoring + Accessibility there."
  echo "Remove any stale TCC entry for ${KEYPOP_APP_LEGACY}."
fi

case ":${PATH}:" in
  *":${INSTALL_PREFIX}:"*) ;;
  *)
    echo ""
    echo "Add to PATH (zsh):"
    echo "  echo 'export PATH=\"${INSTALL_PREFIX}:\$PATH\"' >> ~/.zshrc"
    ;;
esac

echo ""
echo "Running keypop inspect..."
if ! "${INSTALL_PREFIX}/keypop" inspect >/dev/null; then
  echo "error: keypop inspect failed" >&2
  exit 1
fi

echo ""
echo "Installing LaunchAgent for keypop..."
"${PROJECT_DIR}/scripts/launch-keypop.sh" install

echo ""
echo "Next steps:"
echo "  One-time: ./scripts/create-keypop-signing-cert.sh   # stable TCC across rebuilds"
echo "  Grant Input Monitoring + Accessibility to: ${KEYPOP_APP}"
echo "  System Settings → Privacy & Security → click + → Cmd+Shift+G → paste app path"
echo "  keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run"
echo "  ./scripts/launch-keypop.sh restart   # after TCC grants"
echo "  See docs/user-guide.md"
