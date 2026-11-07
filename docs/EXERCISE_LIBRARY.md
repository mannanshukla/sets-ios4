# Exercise library 3.1

The bundled library now contains 880 exercises. The 862 existing IDs and every non-alias field are preserved; 18 additions have original instructions and no photos. Existing photos remain associated with their original exercises. Assisted pull-up/dip machines were deliberately left out because treating their assistance setting as positive resistance would misstate volume and progress.

Custom exercises live in a separate atomic JSON file. Validation runs before writing, names are trimmed, duplicate names are refused, and each exercise receives a stable `custom-` UUID. An unreadable existing file is never replaced by an empty one. Loading filters malformed entries without rewriting them. No custom-exercise save writes routines, active workouts, workout history or bodyweight data.

The Exercises controller retains the catalog array used to build its search index. Returning to the screen reuses that index while the catalog is unchanged. A successful custom save invalidates the store's catalog; the next appearance rebuilds the index and includes the new aliases. Retaining the old array avoids pointer reuse falsely appearing unchanged. Both the index and retained catalog are released with the controller.

The custom editor owns its draft text and logging control across memory-warning reloads. Choosing muscle/equipment updates copied properties. Child choice controllers retain the editor while on the navigation stack, and the editor does not retain those children. Cancel/back leaves no new exercise; Save is the only persistence boundary.

Host checks cover new alias ranking and typos, custom ID stability, duplicate/type validation, corruption refusal and unchanged workout bytes. The native audit adds custom editor reload/deallocation and cache reuse/invalidation checks. Clang static analysis reports no diagnostics in changed store/browser/editor code.

Final iPod touch 4 / iOS 5.1.1 result: 1,217 native assertions, all 450 controller instances released, warm heap change +976 bytes. Ten full-catalog typo searches took 0.885 seconds. The expanded coach prompt remained below the 96,000-character request limit.

The earlier AppKit offscreen resize path had produced 988 blank JPEGs. The importer now uses ImageIO thumbnails, checks decoded pixel variation before saving, and verifies the encoded result. All 1,718 bundled images pass `swift tools/resize_images.swift --verify-only`. Photo associations and original exercise IDs are unchanged.
