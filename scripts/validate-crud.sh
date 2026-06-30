#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
trctl="${root}/.build/debug/trctl"
db="${HOME}/Library/KeyboardServices/TextReplacements.db"
probe=";trctlprobe$(date +%Y%m%d%H%M%S)"

cleanup() {
  "${trctl}" private-delete --i-understand-private-api --shortcut "${probe}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

expect_count() {
  local label="$1"
  local expected="$2"
  local sql="$3"
  local actual
  actual="$(sqlite3 "${db}" "${sql}")"
  printf '%s|%s\n' "${label}" "${actual}"
  if [[ "${actual}" != "${expected}" ]]; then
    printf 'Expected %s for %s, got %s\n' "${expected}" "${label}" "${actual}" >&2
    exit 1
  fi
}

cd "${root}"
swift build >/dev/null

"${trctl}" private-create --i-understand-private-api --shortcut "${probe}" --phrase "TRCTL create validation" >/dev/null
sleep 2
expect_count "after-create" "1" "select count(*) from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0 and ZSHORTCUT = '${probe}' and ZPHRASE = 'TRCTL create validation';"

"${trctl}" private-update --i-understand-private-api --shortcut "${probe}" --phrase "TRCTL update validation" >/dev/null
sleep 2
expect_count "after-update" "1" "select count(*) from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0 and ZSHORTCUT = '${probe}' and ZPHRASE = 'TRCTL update validation';"

"${trctl}" private-delete --i-understand-private-api --shortcut "${probe}" >/dev/null
sleep 2
expect_count "after-delete" "0" "select count(*) from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0 and ZSHORTCUT = '${probe}';"
trap - EXIT
