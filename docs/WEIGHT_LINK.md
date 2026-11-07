# Sets → Meals weight link

Sets 3.3 can publish dated body-weight entries to Meals 1.2 on the same iOS 4.3–5.1.1 device. Turn on **Sets → Progress → Share with Meals**. Meals reads the latest snapshot when opened, and before displaying Progress or adaptive review screens. There is no Mac process, internet request or API key.

## Data ownership

- Sets remains the source of shared weigh-ins. Edit or delete them in Sets; the next snapshot updates the imported view in Meals.
- Meals retains the snapshot separately in its existing settings table. It does not rewrite its manual weights table. A manual Meals weight wins if both apps have a value for the same date.
- Imported rows are labelled Sets and are read-only in Meals. The Use Sets weigh-ins switch excludes them without deleting the cache or manual entries. Turning sharing off in Sets publishes a disabled, empty snapshot.
- Shared weights feed the same seven-day display and adaptive review inputs as manual weights. Source changes invalidate a pending adaptive proposal when relevant to its review window; old applied reviews remain unchanged.
- When Sets is not opened after an external change or restore, Meals has the last received snapshot. No background polling or claim of continuous cloud sync is made.

## Units and preservation

Older Sets rows contain a timestamp and a displayed number but no unit. The first enable or later unit change preserves those original fields, copies the exact prior file to `Documents/bodyweight-before-units.json`, and adds canonical kilograms plus a local calendar date. The pre-upgrade unit is interpreted exactly as Sets currently displays it; previously ambiguous historical unit switches cannot be inferred.

New weigh-ins store kilograms as well as the displayed number. Switching pounds/kilos changes their display, never their physical meaning. A same-day edit replaces that day's Sets record. Invalid source files are kept and sharing cannot be enabled from them. Zero/out-of-range masses and future dates stay in Sets but are excluded from shared data, with a count shown in Meals.

## Transport and validation

The apps use a dedicated persistent named UIPasteboard, `com.mshukla.sets.meals.weights.v1`, with the custom type `com.mshukla.weight-snapshot-v1`. The general clipboard is never read or overwritten. This is a legacy local inter-app transport, not an authenticated or encrypted store for credentials. Only dated weights, source/version metadata and an excluded-entry count are shared. Sharing is off by default in Sets.

Both repos contain identical `WBBridge.h/.m`. The protocol accepts version 1, at most 10,000 rows and a 2 MiB encoded payload. It validates types, finite numbers, dates, unique days and 20–500 kg shared masses. Newer protocol versions are refused. Duplicate source dates choose the latest timestamp. Meals rejects older snapshots and commits a changed snapshot transactionally; a failed save keeps the previous cache and manual data.

Native audit builds use a separate named board and synthetic data. They do not publish test weights to the real app bridge. No timers, singleton observers or retained delegates are added.

Apple's [pasteboard overview](https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/Pasteboard.html) documents named pasteboards for sharing between sibling apps. The bundled iPhoneOS 4.3 SDK exposes the persistent named-board API used here; newer iOS versions changed this mechanism.

## Verification for 1.2 / 3.3

Host regressions pass in both repos, including 24 Meals bridge checks and 15 Sets weight-store checks. Native Sets checks passed 18 cases, including publication, deletion and opt-out on the dedicated test board. The full Meals native audit passed 39,601 assertions; 320 controllers released, with 0 bytes of warm-heap growth. Clang static analysis reported no diagnostics in changed paths.

Installed Meals 1.2 build 3 and Sets 3.3 build 6 in place. Enabled the actual link through Sets' native switch. Meals received all six existing source weigh-ins through the production named board; dates and canonical kilogram values matched. The main Meals tables and existing settings, Sets routine/workout files, and Cards progress files were preserved. Original Sets weight fields remain unchanged, with an exact pre-normalization backup. Final installed executables match the signed builds. Audit apps were removed after checking. No real user weights or screenshots are included in the repositories.
