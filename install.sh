#!/bin/sh
# KeyPop CLI-only bootstrap installer (kept at this curl-friendly URL).
# Fetches KeyPop, builds the CLI from source, and installs it to ~/.local/bin.
# It does not install the app bundle, LaunchAgent, or TCC permissions.
# For the full macOS setup, clone the repo and run scripts/install-full.sh.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Workplace-Labs/keypop/main/install.sh | sh
#
# Overrides:
#   KEYPOP_REPO    git URL or path to build from (default: official repo);
#                  lets you install from a fork before changes merge
#   KEYPOP_REF     branch, tag, or full commit SHA to build (default: main)
#   KEYPOP_PREFIX  install directory (default: ~/.local/bin)
set -eu

REPO="${KEYPOP_REPO:-https://github.com/Workplace-Labs/keypop.git}"
REF="${KEYPOP_REF:-main}"
PREFIX="${KEYPOP_PREFIX:-$HOME/.local/bin}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: requires macOS" >&2
  exit 1
fi

# git and swift both exist as shims even before the CLT are installed, so
# command -v can't tell — probe the CLT themselves.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "error: Xcode Command Line Tools not found. Install them (not full Xcode):" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT INT TERM

echo "KeyPop CLI-only install"
echo "  Installs: ${PREFIX}/keypop"
echo "  Skips:    KeyPop.app, LaunchAgent, Input Monitoring, Accessibility"
echo "Fetching keypop @ ${REF}..."
git init -q "$workdir/keypop"
git -C "$workdir/keypop" fetch -q --depth 1 "$REPO" "$REF"
git -C "$workdir/keypop" checkout -q FETCH_HEAD

"$workdir/keypop/scripts/install-full.sh" --cli-only --prefix "$PREFIX"

echo "KeyPop CLI-only install complete."
echo "For the system-wide expander, clone the repo and run ./scripts/install-full.sh."
