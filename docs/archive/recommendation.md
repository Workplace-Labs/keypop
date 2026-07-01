# Recommendation

Current recommendation: use the private framework approach for a developer-only tool, with Accessibility automation as the supported last resort.

## Why

- The key old private classes still exist on modern macOS.
- Reads work through `_KSTextReplacementCoreDataStore`.
- Create, update, and delete were proven through KeyboardServices private APIs on macOS 26.5.1.
- The framework exposes newer Core Data, CloudKit, server, and XPC-oriented classes, suggesting Apple still maintains a structured internal API.
- The storage layer is SQLite/Core Data with CloudKit sync state, so direct database writes are risky.
- UI automation remains slower, permission-heavy, and brittle.

## Current Risk

- This depends on private APIs and cannot ship through the Mac App Store.
- The exported `_kTextReplacementEntitlement` symbol suggests some internal paths may be entitlement-gated, but the tested create/update/delete path did not require adding custom entitlements.
- Method signatures are inferred from the old project and runtime testing, not public headers.
- The older `_KSTextReplacementClientStore` read selectors returned empty on macOS 26.5.1; read support now uses `_KSTextReplacementCoreDataStore` instead.

## Success Criteria Answers

- Does a modern private API still exist? Yes, for read/create/update/delete through `KeyboardServices.framework`.
- Can it be safely wrapped in Swift? Yes for developer tooling; the package wraps private Objective-C calls behind a Swift CLI and an Objective-C runtime bridge.
- Does it require entitlements? The tested CRUD route did not require custom entitlements. Some untested internal paths may.
- Does it require Accessibility permissions? No Accessibility prompt was observed during the verified CRUD run.
- Is it stable enough to build a developer tool around? Yes for a local developer utility with version checks and fallbacks. No for App Store distribution or a consumer app that needs public API stability.

## Next Validation Gate

Run this from `keypop`:

```sh
swift build
swift test
.build/debug/keypop inspect
.build/debug/keypop read-sources
.build/debug/keypop list
.build/debug/keypop list --prefix ';wl'
scripts/validate-crud.sh
```

On this machine, that round trip succeeded without Accessibility prompts:

- create: active database row count became `1`
- update: active database row with updated phrase count became `1`
- delete: active database row count became `0`

The answer to the main research question is yes: modern macOS still exposes private APIs that can be wrapped in Swift for developer tooling. The main remaining refinement is whether to target the local Core Data store directly, as this prototype does for reads, or move reads to the XPC server connection for a cleaner long-term boundary.
