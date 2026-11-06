# Sets

A stripped-down workout log for iPod touch 4. Your log stays on the device. 365 exercises with photos from free-exercise-db, 123 of them stretches logged as a hold time, a ratchet wheel for weight and reps, rest timer, body weight and estimated one-rep-max charts, and Claude routines grounded in your goal, available equipment, time and recent training.

## Claude integration (2.0)

In **Settings → Sets → AI Coach**, choose Claude, enter an Anthropic API key in the masked field, and optionally set a model ID. The default is `claude-sonnet-5-5`. The older OpenRelay provider and its key remain separate. Nothing reads credentials from another app; keys are never bundled in a build. Legacy iOS requires TLSFix and trusted roots, with certificate verification enabled. Requests go directly to the selected provider over Wi-Fi.

**Routines → Generate** considers your goal, experience, equipment, time and completed workouts. Exercise IDs, equipment, set limits and rep ranges are validated. **Progress → Coach** shows the summary before asking for a review.

Every generated plan opens a review screen. Keep the suggestions you want and tap **Add** to save them; existing plans stay. **Discuss in Claude** opens an editable draft in Claude 3.1 or newer. **Use Draft** puts it in a new chat; **Send** is a separate action. Neither handoff nor coaching changes logs.

Only an explicit Ask/Generate uploads the goal and bounded progress summary. Handoff stays on-device until Send in Claude. Keys live in device preferences, so protect device backups. Claude API billing is separate from a Claude subscription.

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

`./tests/build.sh` runs host transport, cancellation, credential separation, URL handoff and plan-validation tests. `./tests/device-build.sh` builds an isolated audit app for native view loading/unloading and active-request teardown. It never uses a real key. `AUDIT_MAIN=tests/live.m ./tests/device-build.sh` instead builds an opt-in live test using synthetic goals; it requires an API key in the audit app’s own preferences and incurs API usage. See [the state and memory audit](docs/STATE_AND_MEMORY.md).

## License

MIT for the code. Third-party marks and data belong to their owners.
