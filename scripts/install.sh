#!/usr/bin/env bash
# Build trctl + trexpand and install to ~/.local/bin (or --prefix <dir>).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
      echo "  Builds release binaries and copies trctl, trexpand, trexpand-probe to <directory>/."
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

echo "Building release binaries..."
swift build --package-path "$PROJECT_DIR" -c release -q

mkdir -p "$INSTALL_PREFIX"
for name in trctl trexpand trexpand-probe; do
  cp "${PROJECT_DIR}/.build/release/${name}" "${INSTALL_PREFIX}/${name}"
  chmod +x "${INSTALL_PREFIX}/${name}"
  echo "Installed: ${INSTALL_PREFIX}/${name}"
done

"${PROJECT_DIR}/scripts/bundle-trexpand-app.sh" "${INSTALL_PREFIX}/trexpand"

case ":${PATH}:" in
  *":${INSTALL_PREFIX}:"*) ;;
  *)
    echo ""
    echo "Add to PATH (zsh):"
    echo "  echo 'export PATH=\"${INSTALL_PREFIX}:\$PATH\"' >> ~/.zshrc"
    ;;
esac

echo ""
echo "Running trctl inspect..."
if ! "${INSTALL_PREFIX}/trctl" inspect >/dev/null; then
  echo "error: trctl inspect failed" >&2
  exit 1
fi

echo ""
echo "Installing LaunchAgent for trexpand..."
"${PROJECT_DIR}/scripts/launch-trexpand.sh" install

echo ""
echo "Next steps:"
echo "  Grant Input Monitoring + Accessibility to: ${HOME}/.local/Trexpand.app"
echo "  (Remove the old bare 'trexpand' exec entry if present.)"
echo "  System Settings → Privacy & Security → click + → Cmd+Shift+G → paste app path"
echo "  trctl import kits/prompts-core.snippets.json --prefix ';p' --dry-run"
echo "  ./scripts/launch-trexpand.sh restart   # after TCC grants"
echo "  See docs/user-guide.md"
