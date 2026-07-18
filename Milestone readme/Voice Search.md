# Voice Search — Build Writeup

> Ships outside the milestone sequence — a small, self-contained unblock rather than
> part of Milestone 6. Built 2026-07-18.

---

## 1. Why This Wasn't Built Sooner

Voice search was in the original plan (`Plan.md`, `Phase_Plan_Business.md`) from the
start, using the `speech_to_text` package (on-device recognition, no external API
cost). It was removed and deferred twice:

1. **Milestone 1 (2026-07-09)** — `speech_to_text`, `workmanager`, and `posthog_flutter`
   were all pulled from the dependency tree because they broke the Android build under
   Kotlin 2.0. Firebase Analytics replaced PostHog; voice search and background sync
   were deferred "to Phase 5 for re-evaluation."
2. **Milestone 5.5 (Home tab)** — at the re-evaluation point, the call was to defer
   *again* rather than re-litigate a native build-tooling issue mid-milestone. Nothing
   else in 5.5 depended on it — the search bar worked text-only, just no mic icon.

Both deferrals set an explicit revisit condition: re-evaluate once `speech_to_text`
publishes a Kotlin-2.0-compatible release, or once the project's own toolchain moves
past the incompatible version.

## 2. Why Now

While adding search bars to the Catalog and Order Again tabs (matching Home's
always-visible style), the question came up directly: is voice search still
documented as planned anywhere? It was — extensively, in `00_common_architecture.md`
§19–21 and `01_home_tab.md` §5, both specifying a mic icon inside the search bar and a
`voice_search_used` analytics event.

Rather than assume the Kotlin blocker still applied, it was tested directly against
this project's **current** Android setup:

```
android/settings.gradle.kts → kotlin("android") version "2.3.20"
android/app/build.gradle.kts → languageVersion = KOTLIN_2_0
```

The project had already moved well past Kotlin 2.0 since the Milestone 1 removal.
Spike steps:

```bash
flutter pub add speech_to_text        # resolved cleanly at 7.4.0, no conflicts
cd android && ./gradlew :app:compileDebugKotlin   # BUILD SUCCESSFUL
```

`speech_to_text 7.4.0` compiled cleanly — only harmless deprecation warnings from
inside the plugin's own source (unnecessary safe calls, one deprecated Bluetooth API),
no errors. The blocker was resolved; the feature was built the same session.

## 3. What Was Built

### Dependency & permissions
- `pubspec.yaml` — `speech_to_text: ^7.4.0` (comment updated from "removed — deferred"
  to reflect the resolved status and this doc)
- `android/app/src/main/AndroidManifest.xml` — `RECORD_AUDIO` permission added
- `ios/Runner/Info.plist` — `NSMicrophoneUsageDescription` +
  `NSSpeechRecognitionUsageDescription` added (the `ios/` folder exists in this
  project even though it isn't actively built for iOS yet, so this was added for
  correctness)

### Shared widget
`lib/shared/widgets/voice_search_button.dart` — one `VoiceSearchButton` widget used
by all three search bars, rather than duplicating `SpeechToText` init/listen/error
handling three times. Behavior:
- Tap → `SpeechToText.initialize()` (this also handles the `RECORD_AUDIO` permission
  prompt on first use internally) → `listen()`
- Recognized words are pushed into a caller-supplied `onResult(String)` callback on
  each partial result, exactly like a keystroke — so it feeds the *same* debounced
  search path the keyboard already uses on each screen. No separate voice codepath.
- Failure states handled inline (no crash): permission denied or no recognition
  service available on the device → `initialize()` returns `false`, shown as a
  snackbar; mid-listen errors → `onError` callback, also a snackbar; tapping again
  while listening stops the session early.
- Icon swaps between `Icons.mic_none` (idle) and a highlighted `Icons.mic` (listening).

### Wired into all three search bars
Per the original spec's intent ("every search bar gets a mic"), extended to match
where persistent search bars now actually live:
- `home_screen.dart` — original spec location
- `catalog_screen.dart` — Catalog's search was restyled from an icon-toggle to a
  persistent bar (same session), so it got the mic too
- `order_again_screen.dart` — Order Again's search bar is new this session (added
  alongside a month filter for "Previously Bought"); it got the mic for consistency

Each screen's `_onVoiceResult` sets the search `TextEditingController`'s text and
forwards the words into that screen's existing search-change handler — Home/Catalog
call `searchProvider.notifier.onQueryChanged` directly (which has its own internal
debounce), Order Again routes through its own debounced `_onSearchChanged`.

### Deliberately not built
- **`voice_search_used` analytics event** — spec'd in `00_common_architecture.md`
  §22 (originally against PostHog, which was itself removed in the same Kotlin 2.0
  cut and replaced by Firebase Analytics). Explicitly skipped: not worth tracking
  voice-specific adoption at current volume. Trivial to add later
  (`FirebaseAnalytics.instance.logEvent(...)` in `VoiceSearchButton`'s `onResult`)
  if it becomes useful.

## 4. Verification Done

- `flutter analyze` on all touched Dart files — clean
- `flutter pub add speech_to_text` — resolved without dependency conflicts
- `./gradlew :app:compileDebugKotlin` — `BUILD SUCCESSFUL`
- `./gradlew :app:processDebugMainManifest` — manifest (including the new
  `RECORD_AUDIO` permission) merges cleanly

**Not done:** a live on-device test of the actual microphone → recognition →
search-results flow. The build/compile verification confirms the Kotlin blocker is
gone and the code is wired correctly, but the on-device permission-prompt UX and
real speech recognition accuracy haven't been exercised on a physical device or
emulator with mic access.

## 5. Docs Updated Alongside This Build

- `Planning docs/Architecture/01_home_tab.md` §5 — "Voice Search — Deferred" →
  "Voice Search", rewritten as implemented
- `Planning docs/Phase_Plan_Technical.md` — new "Voice Search Update (July 18, 2026)"
  note; the Phase 5.5 "Explicitly deferred" bullet updated to point here
- `Planning docs/Architecture/00_common_architecture.md` — `voice_search_used`
  analytics table row annotated as not implemented (by choice)
- `Milestone readme/Milestone 5.5 pending steps.md` — voice search bullet updated to
  point here instead of describing it as still deferred
