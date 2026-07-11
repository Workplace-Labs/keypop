#!/bin/sh
# Standalone curl-able installer: builds the keypop CLI from source and
# installs the binary to ~/.local/bin. CLI only — does not bundle the app,
# install the LaunchAgent, or touch TCC permissions. For the complete setup
# (system-wide expander, app bundle), clone the repo and run scripts/install.sh.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Workplace-Labs/keypop/main/install.sh | sh
#
# Overrides:
#   KEYPOP_REPO    git URL to build from (default: official repo)
#   KEYPOP_REF     branch, tag, or commit to build (default: main)
#   KEYPOP_PREFIX  install directory (default: ~/.local/bin)
set -eu

REPO="${KEYPOP_REPO:-https://github.com/Workplace-Labs/keypop.git}"
REF="${KEYPOP_REF:-main}"
PREFIX="${KEYPOP_PREFIX:-$HOME/.local/bin}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: requires macOS" >&2
  exit 1
fi

major="$(sw_vers -productVersion | cut -d. -f1)"
if [ "$major" -lt 14 ]; then
  echo "error: macOS 14+ required" >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "error: swift not found. Install Xcode Command Line Tools:" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT INT TERM

echo "Fetching keypop @ ${REF}..."
git init -q "$workdir/keypop"
git -C "$workdir/keypop" fetch -q --depth 1 "$REPO" "$REF"
git -C "$workdir/keypop" checkout -q FETCH_HEAD

echo "Building release binary..."
swift build --package-path "$workdir/keypop" -c release -q

mkdir -p "$PREFIX"
install -m 755 "$workdir/keypop/.build/release/keypop" "$PREFIX/keypop"
echo "Installed: ${PREFIX}/keypop"

"$PREFIX/keypop" inspect >/dev/null
echo "Verified: keypop inspect passed"

case ":${PATH}:" in
  *":${PREFIX}:"*) ;;
  *)
    echo ""
    echo "Add to PATH (zsh):"
    echo "  echo 'export PATH=\"${PREFIX}:\$PATH\"' >> ~/.zshrc"
    ;;
esac
