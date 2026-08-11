# Change Request Log

- CR ID: CR-2026-08-11-StudyMotivation-001
- Date: 2026-08-11
- Repository: dorislileye-collab/Study_Motivation
- Branch: main

## 1) Change Summary

This change request includes consistency fixes between H5 and iOS implementations, game timer logic corrections, white-noise purchase/playback fixes, and runtime UX cleanup for favicon loading.

## 2) Scope of Changes

### iOS (SwiftUI)

- `LearningRecorder-iOS/StudyMotivator/ContentView.swift`
  - Introduced `AppTabRouter` and bound `TabView(selection:)` to shared router state.

- `LearningRecorder-iOS/StudyMotivator/StudyMotivatorApp.swift`
  - Injected `AppTabRouter` via environment.
  - Removed startup-time `recordActive()` call to avoid premature streak check-in.

- `LearningRecorder-iOS/StudyMotivator/Views/Home/HomeView.swift`
  - Updated quick actions to switch tabs directly through shared tab router.
  - Corrected decoration mapping to quote/task-specific decoration APIs.
  - Removed transient toast path no longer needed after direct tab routing.
  - Reworked repeated-task add path to expand recurring dates when repeat days are selected.

- `LearningRecorder-iOS/StudyMotivator/Views/Mine/AchievementsView.swift`
  - Refined `first_theme` achievement condition to require at least one non-default theme.

### H5 (learning-recorder)

- `learning-recorder/src/home.js`
  - Changed internal `switchTab` to delegate to global tab click flow to guarantee page rerender and cleanup hooks.

- `learning-recorder/src/game.js`
  - Recomputed freeze state on each render to prevent stale cross-day frozen status.

- `learning-recorder/src/games/bubble.js`
  - Removed duplicate game-time interval to prevent double counting game usage time.

- `learning-recorder/src/white-noise.js`
  - Fixed coin spending check (`spendCoins` numeric return handling).
  - Added purchase record reason text.
  - Resolved paid-audio paths via `import.meta.url` to support subpath hosting.

- `learning-recorder/src/mine.js`
  - Matched H5 achievement logic with iOS: `first_theme` requires non-default theme ownership.

- `learning-recorder/index.html`
  - Added explicit favicon declaration to avoid default favicon 404 noise.

- Added icon assets:
  - `learning-recorder/favicon.svg`
  - `learning-recorder/favicon.ico`
  - `favicon.ico` (root-level fallback)

## 3) Validation Performed

- JS syntax checks completed for modified JS files (`node --check`) with no errors.
- Editor diagnostics checked for modified files with no reported errors.
- H5 runtime smoke tested via local static server:
  - Tab navigation and page rerender behavior validated.
  - Game unlock and countdown behavior verified.
  - White-noise purchase flow validated for insufficient and sufficient coins.
  - Paid audio request path validated under `/learning-recorder/` subpath.
  - Favicon request validated (`/learning-recorder/favicon.svg` -> HTTP 200).
- iOS smoke build executed with `xcodebuild` using iOS Simulator destination.
  - Result: `BUILD SUCCEEDED`.

## 4) Risk and Impact

- Low-to-medium risk, concentrated in navigation, state, and media-loading paths.
- No schema/storage migration introduced.
- Behavior changes are intentional and aligned with H5-iOS parity goals.

## 5) Rollback Plan

- Revert commit for this CR if regression is found:
  - `git revert <commit_sha>`

## 6) Notes

- Existing user data in localStorage/UserDefaults is preserved.
- Root-level favicon fallback is included for environments that still request `/favicon.ico` by default.
