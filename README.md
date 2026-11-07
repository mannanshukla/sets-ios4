# Sets

A stripped-down workout log for iPod touch 4. Your log stays on the device. 900 built-in exercises, with 1,718 photos from free-exercise-db, including stretches logged as a hold time, a ratchet wheel for weight and reps, rest timer, body weight and estimated one-rep-max charts, and Claude routines grounded in your goal, available equipment, time and recent training.

## Coach (3.0)

In **Settings → Sets → AI Coach**, choose Claude, enter an Anthropic API key in the masked field, and optionally set a model ID. The default is `claude-sonnet-5-5`. The older OpenRelay provider and its key remain separate. Nothing reads credentials from another app; keys are never bundled in a build. Legacy iOS requires TLSFix and trusted roots, with certificate verification enabled. Requests go directly to the selected provider over Wi-Fi.

**Coach** is a dedicated tab: check in with your goal, energy, recovery and available time; review your week; ask questions; revisit saved notes. **Your routines** keeps your existing program close. **Build a plan** considers your experience, equipment, time and completed workouts, then validates exercise IDs, equipment, set limits and rep ranges. **Workout → Routines** also opens your routine library.

Every generated plan opens a review screen. Keep the suggestions you want and tap **Add** to save them; existing plans stay. **Discuss in Claude** opens an editable draft in Claude 3.2 or newer. **Use Draft** puts it in a new chat; **Send** is a separate action. Neither handoff nor coaching changes logs.

Only an explicit Ask or Review a New Plan uploads the goal and bounded progress summary. Handoff stays on-device until Send in Claude. Keys live in device preferences, so protect device backups. Claude API billing is separate from a Claude subscription.

## Weight sharing (3.3)

Turn on **Progress → Share with Meals** to reuse Sets weigh-ins in Meals 1.2. Updates stay on the iPod and appear when Meals is opened. Existing entries are backed up before adding stable kilogram values, so changing units preserves their meaning. [Data ownership and checks](docs/WEIGHT_LINK.md).

## Catalog review (3.2)

Adds 20 common machine, cable, barbell and bodyweight movements after comparing established exercise libraries. Search now recognizes Nordic curls, ring rows, reverse lunges and more familiar names for existing entries. Original IDs and progress remain unchanged. [Added movements, sources and checks](docs/CATALOG_REVIEW.md).

## Exercise library (3.1)

Adds belt and pendulum squats, Bayesian curls, cable and machine variations, tibialis raises, landmine movements and single-leg work. Existing names gain aliases such as reverse pec deck, chest-supported row and hip abduction. The 18 new entries have original instructions; they do not show unrelated photos.

**Exercises → +** creates a custom exercise with a muscle, equipment, hidden search aliases and either weight/reps or timed-hold logging. Custom entries get stable IDs in `Documents/custom-exercises.json`; bundled IDs, routines and workout history are untouched. Unreadable custom files are preserved and further saves are refused.

## Search and logging

Search works offline, ranking exact names and hidden aliases before prefixes and bounded Damerau–Levenshtein token matches. Try `RDL`, `pec deck`, `skull crushers`, `dumbell curl` or `bnech press`. Muscle and equipment tags are searchable without cluttering the exercise title. All/Lifts/Stretches filters include the expanded catalog. Existing exercise IDs and records remain unchanged.

The weight wheel steps by 0.5 lb or 0.25 kg. **Exact** accepts weights such as 13 or 13.25. Changing reps does not round the weight already recorded. Coaching notes use native Core Text, Helvetica, paper, headings and bullets. Long notes scroll as one page; wide code and tables have their own inset box.

## Layout

- `res/exercises.json` and `res/exercises/` are curated from [free-exercise-db](https://github.com/yuhonas/free-exercise-db), public domain.
- `src/LFStore` is the JSON store and all the stats. `LFWorkoutViewController` has the drum picker. `LFAI` generates routines and validates every exercise id against the bundle.

## Building

Targets iOS 4.3 on armv7 from a modern Mac with only the Command Line Tools installed. No Xcode.

1. Get the iPhoneOS 4.3 SDK from [EachAndOther/Legacy-iOS-SDKs](https://github.com/EachAndOther/Legacy-iOS-SDKs) into `~/ios4sdk/iPhoneOS4.3.sdk`.
2. The modern linker refuses the old dylibs, so convert them to text stubs once: run `tapi stubify` from the Command Line Tools over the SDK's frameworks and retarget the `-darwin` platform strings to `-ios`.
3. `./build.sh` compiles with `clang -target armv7-apple-ios4.3 -fobjc-runtime=ios-4.3 -fno-objc-arc -marm`, pseudo-signs with `ldid -S`, and zips an IPA into `build/`. ARM mode matters: modern ld drops the Thumb bit on Objective-C method pointers for this target and the app crashes at launch without it.
4. Install on a jailbroken device with AppSync: `ideviceinstaller install build/<App>.ipa`.

Everything is hand-written Foundation and UIKit from 2011. The JSON parser is in `src/ORJSON.m` because iOS 4 has no NSJSONSerialization.

## Verification

`./tests/build.sh` runs host transport, cancellation, credential separation, URL handoff and plan-validation tests. `./tests/device-build.sh` builds an isolated audit app for native view loading/unloading and active-request teardown. It never uses a real key. `AUDIT_MAIN=tests/live.m ./tests/device-build.sh` instead builds an opt-in live test using synthetic goals; it requires an API key in the audit app’s own preferences and incurs API usage. See [the state and memory audit](docs/STATE_AND_MEMORY.md) and [exercise-library invariants](docs/EXERCISE_LIBRARY.md).

## License

MIT for the code. Third-party marks and data belong to their owners.
