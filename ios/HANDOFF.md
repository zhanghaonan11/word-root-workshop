# iOS Handoff — WordRootWorkshop (2026-03-02)

This document summarizes the work completed in the iOS app and what to do next.

Repo path: `/Users/shan/github/word-root-workshop/ios`
Remote: `origin https://github.com/zhanghaonan11/word-root-workshop.git`
Branch baseline: `main` (v0.1–v0.3)

## Goals

- Improve **interaction/UX** and **runtime smoothness/performance**.
- Work in small iterations: implement → verify → changelog → commit → tag.

## Tooling notes

- `rg` (ripgrep) may be unavailable in some codex environments; fallback to `find/grep/sed`.

## Delivered versions

### v0.1 (tag: `v0.1`)

Focus: startup load + RootsIndex search/list smoothness + Flashcard drag/animation responsiveness.

Key points:
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

### v0.4 (tag: `v0.4`)

Focus (chosen from suggested next iteration):
- `1) Learning/Quiz flow polish`
- `3) Design system consistency`

Selection reason:
- Highest ROI under current priority “交互一致性/数据可靠性”: user-facing clarity improves immediately and changes stay local (low regression risk).
- Data reliability can be improved with small, isolated normalization logic in `ProgressStore` without changing external APIs.

Acceptance criteria:
- Quiz submission has explicit states (`correct`/`incorrect`/`invalid`), no ambiguous bool branch.
- Invalid quiz state uses consistent visual and haptic feedback, aligned with design system semantics.
- Learn flow CTA/hint/supporting text stay consistent with the latest quiz result and do not leak across roots.
- Imported/loaded progress data is normalized (dedupe, clamp, sort) to avoid corrupted state propagation.
- Local iOS simulator generic build passes.

Key points:
- `QuizSectionView`: `onSubmitResult` upgraded from `Bool` to `SubmissionResult` enum, with explicit invalid-state handling.
- `QuizSectionView`: invalid-state icon/border/background/haptic unified as warning semantics.
- `LearnView`: next-step CTA + hint + supporting text are result-driven; result state resets on root switch/sync.
- `ProgressStore`: load/import sanitization added for progress and achievements (dedupe + bounds + derived minimums).
- `CHANGELOG.md`: v0.4 notes updated to match interaction consistency and reliability priorities.

Primary files touched:
- `WordRootWorkshop/Views/QuizSectionView.swift`
- `WordRootWorkshop/Views/LearnView.swift`
- `WordRootWorkshop/Services/ProgressStore.swift`
- `CHANGELOG.md`
- `HANDOFF.md`

Performance/interaction impact:
- Interaction: clearer quiz feedback and next-step affordance, reduced state confusion across card transitions.
- Reliability: safer restore/import path for progress payloads; lower risk of duplicate/invalid persisted state.
- Performance: sanitization happens only on init/import paths (non-hot path), runtime overhead is negligible.

Rollback points:
- Full rollback: revert the v0.4 commit (or reset to tag `v0.3`).
- Partial rollback option A: revert `WordRootWorkshop/Views/QuizSectionView.swift` + `WordRootWorkshop/Views/LearnView.swift`.
- Partial rollback option B: revert `WordRootWorkshop/Services/ProgressStore.swift` if only data-normalization behavior needs to be removed.

## Verification

Each version’s `CHANGELOG.md` entry records a local build verification command, e.g.:

```bash
xcodebuild -project WordRootWorkshop.xcodeproj \
  -scheme WordRootWorkshop \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  build
```

## Current git state (local snapshot)

- `main` baseline includes v0.1–v0.3.
- v0.4 work exists on feature branch and tag context.

## Suggested next iteration (v0.5)

Pick 1–2 to keep scope safe:

1) Measurement-driven performance:
- Add lightweight startup/view timing instrumentation and align with Instruments baselines.

2) Small high-value features:
- Search highlight, favorites/marks, review queue strategy.
