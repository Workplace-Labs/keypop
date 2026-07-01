#!/usr/bin/env bash
# Build trctl and install to ~/.local/bin (or --prefix <dir>).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_PREFIX="${HOME}/.local/bin"
BINARY_NAME="trctl"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      INSTALL_PREFIX="${2:?missing value for --prefix}"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--prefix <directory>]"
      echo "  Builds release trctl and copies to <directory>/trctl (default: ~/.local/bin)."
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: trctl requires macOS" >&2
  exit 1
fi

major="$(sw_vers -productVersion | cut -d. -f1)"
if [[ "${major}" -lt 14 ]]; then
  echo "error: macOS 14+ required (found $(sw_vers -productVersion))" >&2
  exit 1
fi

echo "Building trctl (release)..."
swift build --package-path "$PROJECT_DIR" -c release -q

SRC="${PROJECT_DIR}/.build/release/${BINARY_NAME}"
DEST="${INSTALL_PREFIX}/${BINARY_NAME}"

mkdir -p "$INSTALL_PREFIX"
cp "$SRC" "$DEST"
chmod +x "$DEST"

echo "Installed: ${DEST}"

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
if ! "$DEST" inspect >/dev/null; then
  echo "error: trctl inspect failed — KeyboardServices may be unavailable on this OS." >&2
  exit 1
fi

echo ""
echo "Next steps:"
echo "  trctl list"
echo "  trctl import kits/prompts-core.raycast.json --prefix ';p' --dry-run"
echo "  See docs/user-guide.md"
