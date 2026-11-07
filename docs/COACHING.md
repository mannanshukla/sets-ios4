# Coach 3.0 design and data contract

The central flow is **keep a program → check in → review → make a small adjustment**. Plans are optional, reviewed additions. There is no automatic program replacement, weight escalation, or workout logging.

Public references informing the design:

- [Trainer Winny](https://www.trainerwinny.com/) emphasizes a simple training plan and consistency. His [public coaching description](https://trainerwinny.com/moreinfo) describes customizable guidelines and questions about current obstacles. No paid program, branded persona or proprietary plan was copied.
- [Trainerize check-ins](https://help.trainerize.com/hc/en-us/articles/31369316335124-Sharing-Check-In-Forms-with-Clients) cover energy, soreness, goal progress and feedback. Sets captures a dated goal/obstacles, energy, recovery and time check-in.
- [Fitbod exercise variability](https://help.fitbod.me/hc/en-us/articles/29976242163223-Exercise-Variability) offers consistency across weeks. Sets asks the coach to work from the existing routines instead of constantly replacing exercises.
- [NIST edit distance](https://xlinux.nist.gov/dads/HTML/Levenshtein.html) describes insertion, deletion and substitution. `LFSearch` adds adjacent transposition (optimal string alignment), bounded to one edit for 3–6-character tokens and two for longer tokens. Exact aliases rank ahead of fuzzy matches. Query length, token count and edit matrices are bounded; the index is local and search is debounced by 120 ms.

`routines.json`, `workouts.json`, `active.json` and `bodyweight.json` keep their existing schemas. No data migration is performed. New check-ins and at most 30 coaching notes use separate preference keys. Existing `ai_last_review` is visible as an earlier note. Requests have explicit states and cancel on navigation/backgrounding; failed requests do not overwrite saved notes. The review summary includes up to eight recent completed workouts, four weeks of volume, six routines and the dated check-in. Review it before sending.

All 365 original exercise objects, excluding the additive aliases field, are unchanged. The catalog appends 497 non-cardio records from [free-exercise-db](https://github.com/yuhonas/free-exercise-db), commit `f00c92c7dcf1216a928a52c3706c7ce8e2f71ed5`, under its Unlicense. Photos are resized only for device memory and download size. `tools/expand_exercises.py` resumes downloads; `tools/resize_images.swift` converts the new images. Human aliases are search hints, never rewritten exercise identities.

Native audits use an isolated app/container, synthetic routines and mock credentials. They cover exact-weight parsing, preserving fractional weight when changing reps, 13 lb wheel selection, expanded prompt limits, long Markdown pagination, memory-warning reloads, pending-request teardown and repeated deallocation. They do not edit the user's data. Static analysis complements these checks; bounded test results are not proof that every possible path is leak-free.
