# Symbol Inventory

## Framework Presence

Observed framework and related resources:

- `/System/Library/PrivateFrameworks/KeyboardServices.framework`
- `/System/Library/Frameworks/InputMethodKit.framework`
- `/System/Library/PrivateFrameworks/TextInput.framework`
- `/System/Library/PrivateFrameworks/TextInputUI.framework`
- `/System/Library/PrivateFrameworks/TextInputCore.framework`
- `/System/Library/PrivateFrameworks/TextInputMenuUI.framework`

`InputMethodKit.framework` is public on this machine, not private.

## KeyboardServices Exports

Relevant Objective-C classes exported by `dyld_info -exports`:

- `_KSTextReplacementClientStore`
- `_KSTextReplacementEntry`
- `_KSTextReplacementHelper`
- `_KSTextReplacementCoreDataStore`
- `_KSTextReplacementCKStore`
- `_KSTextReplacementLegacyStore`
- `_KSTextReplacementManagedObject`
- `_KSTextReplacementManager`
- `_KSTextReplacementServer`
- `_KSTextReplacementServerConnection`
- `_KSTIUserDictionaryEntryValue`
- `_KSTIUserDictionaryTransaction`
- `_KSCKSyncStateManagedObject`
- `_KSCloudKitManager`

Relevant constants/symbols:

- `_KSTextReplacementDidChangeNotification`
- `__KSTextReplacementServerInterface`
- `__KSTextReplacementErrorDomain`
- `__KSTextReplacementEntryDidFailErrorKey`
- `__KSTextReplacementUpdateDidFailEntriesKey`
- `__KSTextReplacementDeleteDidFailEntriesKey`
- `_kTextReplacementEntitlement`
- `_kKeyboardServicesCloudKitContainerID`

`dyld_info -objc` cannot print live Objective-C method metadata from dyld shared cache dylibs on this system, so selector validation currently relies on runtime `respondsToSelector:` checks.

Runtime method ownership confirms:

- `_KSTextReplacementClientStore`
  - `addEntries:removeEntries:withCompletionHandler:`
  - `modifyEntry:toEntry:withCompletionHandler:`
  - `performTransaction:completionHandler:`
  - `textReplacementEntries`
  - `queryTextReplacementsWithCallback:`
- `_KSTextReplacementCoreDataStore`
  - `queryEntriesWithPredicate:limit:`
  - `textReplacementEntriesWithLimit:`
  - `recordTextReplacementEntries:`
  - `deleteTextReplacementsWithPredicate:`
- `_KSTextReplacementServerConnection`
  - `serviceConnection`
  - `addEntries:removeEntries:withReply:`
  - `queryTextReplacementEntriesWithReply:`
- `_KSTextReplacementHelper`
  - `textReplaceEntryFromTIDictionaryValue:`
  - `transactionFromTextReplacementEntry:forDelete:`
  - `validateTextReplacement:`

## Old Project Comparison

`rodionovd/shortcuts` used `KeyboardServices+Private.h` declarations for:

- `_KSTextReplacementClientStore`
  - `textReplacementEntries`
  - `performTransaction:completionHandler:`
  - `modifyEntry:toEntry:withCompletionHandler:`
  - `queryTextReplacementsWithCallback:`
  - `queryTextReplacementsWithPredicate:callback:`
- `_KSTextReplacementEntry`
  - `shortcut`
  - `phrase`
  - `priorValue`
- `_KSTextReplacementHelper`
  - `validateTextReplacement:`
  - `transactionFromTextReplacementEntry:forDelete:`
  - `errorStringForCode:`

Those class names are still exported on macOS 26.5.1. The prototype uses the same broad route without importing private headers at compile time.

One important signature drift was observed: `performTransaction:completionHandler:` can call `textReplaceEntryFromTIDictionaryValue:` on `_KSTextReplacementClientStore`, but that class no longer owns the selector. `_KSTextReplacementHelper` does. The working create/delete route avoids this by using `addEntries:removeEntries:withCompletionHandler:`.

The old client-store read selectors still return empty on this OS. The working read route is `_KSTextReplacementCoreDataStore textReplacementEntriesWithLimit:`.
