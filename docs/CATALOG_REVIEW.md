# Catalog review, Sets 3.2

Compared the existing catalog with [StrengthLog's exercise directory](https://www.strengthlog.com/exercise-directory/) and [Hevy's exercise-library workflow](https://www.hevyapp.com/features/exercise-library). Conventional names were used to identify gaps; the added instructions were authored for Sets, and no competitor photos or videos were copied.

The library grows from 880 to 900 exercises:

- Cable Hip Abduction
- Reverse Nordic Curl
- Safety Bar Squat
- Smith Machine Front Squat
- Smith Machine Lunge
- Machine Lat Pulldown
- Neutral-Grip Lat Pulldown
- Seal Row
- Pendlay Row
- Poliquin Step-Up
- Machine Glute Kickback
- Frog Pumps
- Dumbbell Frog Pumps
- Cossack Squat
- Barbell Reverse Lunge
- Bodyweight Reverse Lunge
- Dumbbell Romanian Deadlift
- Single-Leg Hip Thrust
- Paused Barbell Squat
- Dead Bug with Dumbbells

Fifteen existing records gain aliases. Nordic curls resolve to Natural Glute Ham Raise; ring/TRX rows resolve to Suspended Row; reverse dumbbell lunges resolve to Dumbbell Rear Lunge; deficit reverse lunges resolve to Elevated Back Lunge. Familiar neutral/supinated pulldown, machine-row and donkey-kick names are also searchable. Distinct grip/equipment variations remain separate when their movement or setup differs.

Every original exercise ID and non-alias field is preserved. Existing aliases are only extended. No workout, routine, custom exercise or progress file is migrated. The new entries use instructions without unrelated photos. All 1,718 previously repaired photos remain intact.

Validation: host typo/alias ranking covers Nordic curls, hip abductions, dumbbell RDLs, seal rows, ring rows and Pendlay rows. A native catalog audit verifies the 900-entry library, representative results and the coach request budget. The source schema and UIKit behavior are unchanged from 3.1.

On the iPod touch 4 / iOS 5.1.1, the native catalog audit passed all representative searches with 900 records. The coach prompt was 54,549 characters, below its 96,000-character limit. Sets 3.2 (build 5) was installed in place; the existing body-weight, routine and workout files matched their pre-upgrade SHA-256 hashes. The isolated audit app was removed.
