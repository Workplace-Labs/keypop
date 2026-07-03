#!/usr/bin/env bash
# Shared install paths. Source from other scripts: source "$(dirname "$0")/keypop-paths.sh"
#
# Override app location: KEYPOP_APP=/custom/KeyPop.app ./scripts/install.sh

KEYPOP_APP="${KEYPOP_APP:-${HOME}/Applications/KeyPop.app}"
KEYPOP_APP_LEGACY="${HOME}/.local/KeyPop.app"
KEYPOP_BIN_DIR="${HOME}/.local/bin"
KEYPOP_CLI="${KEYPOP_BIN_DIR}/keypop"
KEYPOP_LOG="${HOME}/.local/log/keypop.log"
KEYPOP_SNIPPETS="${HOME}/.config/keypop/snippets.json"

remove_legacy_app_bundle() {
  if [[ -d "$KEYPOP_APP_LEGACY" && "$KEYPOP_APP" != "$KEYPOP_APP_LEGACY" ]]; then
    echo "Removing legacy app bundle: ${KEYPOP_APP_LEGACY}"
    rm -rf "$KEYPOP_APP_LEGACY"
  fi
}
