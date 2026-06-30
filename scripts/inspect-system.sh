#!/usr/bin/env bash
set -euo pipefail

framework="/System/Library/PrivateFrameworks/KeyboardServices.framework/KeyboardServices"
db="${HOME}/Library/KeyboardServices/TextReplacements.db"

echo "== OS =="
sw_vers
uname -a

echo
echo "== Related frameworks =="
find /System/Library/PrivateFrameworks /System/Library/Frameworks \
  -maxdepth 1 \
  \( -iname '*Text*' -o -iname '*Keyboard*' -o -iname '*Input*' -o -iname '*Dictionary*' \) \
  -print | sort

echo
echo "== KeyboardServices resources =="
find /System/Library/PrivateFrameworks/KeyboardServices.framework/Versions/A/Resources \
  -maxdepth 2 -type f -print | sort

echo
echo "== KeyboardServices exports matching text replacement terms =="
dyld_info -exports "$framework" 2>&1 \
  | rg 'KSTextReplacement|KSTR|TextReplacement|KeyboardServices|UserDictionary|Entitlement|CloudKit|CoreData|Server|ClientStore|Helper|Entry' \
  || true

echo
echo "== KeyboardServices imports matching architecture terms =="
dyld_info -imports "$framework" 2>&1 \
  | rg 'CloudKit|CoreData|NSXPC|xpc_|NSUserDefaults|notify_post|NSSQLite|Ubiquitous|Preferences' \
  || true

echo
echo "== Core Data model strings =="
strings /System/Library/PrivateFrameworks/KeyboardServices.framework/Resources/_KSTextReplacementModel.mom \
  | rg 'TextReplacement|CloudKit|phrase|shortcut|uniqueName|ManagedObject|SyncState' \
  || true

echo
echo "== Local database schema =="
if [[ -f "$db" ]]; then
  file "$db"
  sqlite3 "$db" '.tables' '.schema ZTEXTREPLACEMENTENTRY' '.schema ZTRCLOUDKITSYNCSTATE' \
    'select count(*) as active_entries from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0;'
else
  echo "No database at $db"
fi
