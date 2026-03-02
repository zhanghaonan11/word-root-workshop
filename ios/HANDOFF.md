# iOS Handoff — WordRootWorkshop (2026-03-02)

This document summarizes the work completed in the iOS app and what to do next.

Repo path: `/Users/shan/github/word-root-workshop/ios`
Remote: `origin https://github.com/zhanghaonan11/word-root-workshop.git`
Branch: `main`

## Goals

- Improve **interaction/UX** and **runtime smoothness/performance**.
- Work in small iterations: implement → verify → changelog → commit → tag.

## Tooling notes

- Telegram does **not** support ACP thread binding, so we couldn’t keep a thread-bound `runtime="acp"` session.
- We drove Codex via local **acpx** persistent session (telephone-game style):
  - Session name: `oc-codex-tg--1003825093721-324`
  - The codex-acp agent occasionally disconnected with `connection_close`; git history is the source of truth.
- `rg` (ripgrep) was unavailable in the codex environment; used `find/grep/sed`.

## Delivered versions

All changes are pushed to `origin/main` and tags are pushed.

### v0.1 (tag: `v0.1`)

Focus: startup load + RootsIndex search/list smoothness + Flashcard drag/animation responsiveness.

Key points (see `ios/CHANGELOG.md` for details):
- `WordRootRepository`: moved duplicate-id validation and index-building off the main thread; used `Data(contentsOf:options: [.mappedIfSafe])` for `wordRoots.json`.
- `RootsIndexView`: background index build, cancellable tasks, debounce filtering, and “筛选中...” state to reduce UI thrash.
- `FlashcardView`: reduced implicit per-frame animations during drag; used `predictedEndTranslation` for swipe decision; reused haptic generator.

Primary files touched:
- `WordRootWorkshop/Services/WordRootRepository.swift`
- `WordRootWorkshop/Views/RootsIndexView.swift`
- `WordRootWorkshop/Views/FlashcardView.swift`
- `CHANGELOG.md`

### v0.2 (tag: `v0.2`)

Focus: persisted cache to speed subsequent launches + further RootsIndex rendering optimization.

Key points:
- Added persisted cache in Application Support: `word_roots_cache_v1.plist` containing decoded roots + search index.
- Cache invalidation uses `schemaVersion` + `SHA256` hash of bundled `wordRoots.json`.
- `WordRootRepository` now produces/owns `searchIndex` so views don’t rebuild searchable text repeatedly.
- `RootsIndexView` consumes prebuilt index records and preformatted fields to reduce per-row computation.

Primary files touched:
- `WordRootWorkshop/Models/WordRootModels.swift`
- `WordRootWorkshop/Services/WordRootRepository.swift`
- `WordRootWorkshop/Views/RootsIndexView.swift`
- `CHANGELOG.md`

### v0.3 (tag: `v0.3`)

Focus: Flashcard state isolation + progress persistence smoothness.

Key points:
- Introduced `FlashcardInteractiveCard` to isolate drag/flip state and reduce parent-view invalidations.
- Improved drag feedback (subtle scale + direction hint); ensured state resets when switching cards.
- `ProgressStore`: debounced and moved persistence writes to background queue; added `flushPendingWrites()` and invoked it when scenePhase transitions to `inactive/background` to reduce data-loss risk.

Primary files touched:
- `WordRootWorkshop/Views/FlashcardView.swift`
- `WordRootWorkshop/Services/ProgressStore.swift`
- `WordRootWorkshop/App/WordRootWorkshopApp.swift`
- `CHANGELOG.md`

## Verification

Each version’s `CHANGELOG.md` entry records a local build verification command, e.g.:

```bash
xcodebuild -project WordRootWorkshop.xcodeproj \
  -scheme WordRootWorkshop \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  build
```

## Current git state (as of this handoff)

- `main` includes v0.1–v0.3 changes and is pushed.
- Tags pushed: `v0.1`, `v0.2`, `v0.3`.

## Suggested next iteration (v0.4)

Pick 1–2 to keep scope safe:

1) Learning/Quiz flow polish:
- Better feedback loops, error states, and micro-interactions.

2) Measurement-driven performance:
- Add lightweight startup/view timing instrumentation; align with Instruments.

3) Design system consistency:
- Motion curves, spacing, control sizing, haptics consistency.

4) Small high-value features:
- Search highlight, favorites/marks, review queue strategy.
