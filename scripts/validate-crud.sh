#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
db="${HOME}/Library/KeyboardServices/TextReplacements.db"
snippets="${HOME}/.config/keypop/snippets.json"
probe=";keypopprobe$(date +%Y%m%d%H%M%S)"

resolve_keypop() {
  if command -v keypop >/dev/null 2>&1; then
    command -v keypop
    return
  fi
  local installed="${HOME}/.local/bin/keypop"
  if [[ -x "$installed" ]]; then
    echo "$installed"
    return
  fi
  local built="${root}/.build/debug/keypop"
  if [[ -x "$built" ]]; then
    echo "$built"
    return
  fi
  echo "Building keypop..."
  swift build --package-path "$root" -q
  echo "${root}/.build/debug/keypop"
}

keypop="$(resolve_keypop)"

cleanup() {
  "${keypop}" delete --shortcut "${probe}" >/dev/null 2>&1 || true
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

expect_snippet_sync() {
  local label="$1"
  local phrase="$2"
  if [[ ! -f "${snippets}" ]]; then
    printf 'Expected snippets file at %s after %s\n' "${snippets}" "${label}" >&2
    exit 1
  fi
  for _ in {1..10}; do
    if jq -e --arg shortcut "${probe}" --arg text "${phrase}" \
      '.[] | select(.keyword == $shortcut and .text == $text)' "${snippets}" >/dev/null; then
      printf 'snippets-sync|%s\n' "${label}"
      return 0
    fi
    sleep 1
  done
  printf 'Expected %s in %s after %s\n' "${probe}" "${snippets}" "${label}" >&2
  exit 1
}

expect_snippet_absent() {
  local label="$1"
  for _ in {1..10}; do
    if ! jq -e --arg shortcut "${probe}" '.[] | select(.keyword == $shortcut)' "${snippets}" >/dev/null 2>&1; then
      printf 'snippets-sync|%s\n' "${label}"
      return 0
    fi
    sleep 1
  done
  echo "Expected probe shortcut removed from snippets after delete" >&2
  exit 1
}

cd "${root}"

create_out="$("${keypop}" create --shortcut "${probe}" --phrase "keypop create validation" 2>&1)"
printf '%s\n' "${create_out}"
grep -q 'keypop_sync|' <<<"${create_out}" || {
  echo "Expected keypop_sync line after create" >&2
  exit 1
}
sleep 2
expect_count "after-create" "1" "select count(*) from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0 and ZSHORTCUT = '${probe}' and ZPHRASE = 'keypop create validation';"
expect_snippet_sync "after-create" "keypop create validation"

update_out="$("${keypop}" update --shortcut "${probe}" --phrase "keypop update validation" 2>&1)"
printf '%s\n' "${update_out}"
grep -q 'keypop_sync|' <<<"${update_out}" || {
  echo "Expected keypop_sync line after update" >&2
  exit 1
}
sleep 2
expect_count "after-update" "1" "select count(*) from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0 and ZSHORTCUT = '${probe}' and ZPHRASE = 'keypop update validation';"
expect_snippet_sync "after-update" "keypop update validation"

delete_out="$("${keypop}" delete --shortcut "${probe}" 2>&1)"
printf '%s\n' "${delete_out}"
grep -q 'keypop_sync|' <<<"${delete_out}" || {
  echo "Expected keypop_sync line after delete" >&2
  exit 1
}
sleep 2
expect_count "after-delete" "0" "select count(*) from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0 and ZSHORTCUT = '${probe}';"
expect_snippet_absent "after-delete"

trap - EXIT
