# HTML5 Print Mode - Management Summary

**Date**: February 6, 2026
**Status**: Implementation Plan Consolidated
**Document**: `HTML5_PRINT_Missing_Features.xml`

## Executive Overview

The HTML5 print backend has achieved ~65% feature parity with the PDF backend. The remaining gaps are documented in the consolidated implementation plan with **18 features** organized into **3 parallel execution branches**.

## Feature Breakdown

| Category | Count | Status |
|----------|-------|--------|
| **To Implement** | 12 | Planned |
| **Denied** | 6 | Justified |

### Priority Distribution

| Priority | Count | Features |
|----------|-------|----------|
| CRITICAL | 2 | Paged Mode Activation, FormatGenerator Integration |
| HIGH | 4 | Rechorus, Delegates, Comment Box, Section Labels |
| MEDIUM | 8 | TOC, Odd/Even, Grid Bars, Volta, Image Align, Diagram Pos, Chords-Under, Inline Chords, Keyboard Diagrams |
| LOW | 4 | TOC, Cover/Matter, Song Sorting |

## Parallel Branch Architecture

Three branches can be implemented in parallel after the critical foundation work:

```
                        [START]
                           |
         +-----------------+-----------------+
         |                 |                 |
    [BRANCH A]        [BRANCH B]        [BRANCH C]
   Core + Songbook    Content + Layout   CSS/Styling
         |                 |                 |
    1. Paged Mode     3. Rechorus       6. Comment Box
    2. FormatGen      4. Delegates      7. Section Labels
         |            5. Annotations     8. Grid Bars
    [MERGE A]         10. Image Align    9. Volta
         |            11. Diagram Pos        |
    15. TOC           12. Chords-Under  [BRANCH C DONE]
    16. Odd/Even      13. Inline Chords
    17. Cover/Matter  14. Keyboard Diag
    18. Song Sorting        |
         |            [BRANCH B DONE]
         |                 |
         +-----------------+
                  |
            [FINAL MERGE]
```

### Branch A: Core Infrastructure + Songbook (Sequential)
**Blocker**: Features 1-2 must complete before 15-18

| # | Feature | Priority |
|---|---------|----------|
| 1 | Paged Mode Activation | CRITICAL |
| 2 | FormatGenerator Integration | CRITICAL |
| 15 | Table of Contents | HIGH |
| 16 | Odd/Even Pages | MEDIUM |
| 17 | Songbook Parts (Cover/Matter) | LOW |
| 18 | Song Sorting | LOW |

### Branch B: Content Rendering + Layout (Parallel)
**No dependencies** - can start immediately

| # | Feature | Priority |
|---|---------|----------|
| 3 | Chorus Recall (Rechorus) | HIGH |
| 4 | Delegate Support (ABC/LilyPond) | HIGH |
| 5 | Annotations | MEDIUM |
| 10 | Image Alignment | MEDIUM |
| 11 | Chord Diagram Positioning | MEDIUM |
| 12 | Chords-Under Mode | MEDIUM |
| 13 | Inline Chords Mode | MEDIUM |
| 14 | Keyboard Diagrams | MEDIUM |

### Branch C: CSS/Styling (Parallel)
**Pure CSS** - can start immediately

| # | Feature | Priority |
|---|---------|----------|
| 6 | Comment Box Styling | HIGH |
| 7 | Section Label Display | HIGH |
| 8 | Grid Bar Lines | MEDIUM |
| 9 | Volta Brackets | MEDIUM |

## Denied Features (Justified)

| Feature | Reason |
|---------|--------|
| Chords Column (side) | Complex CSS grid, alternatives exist (chords-under, inline) |
| Strum Patterns | Covered by delegate support (Feature 4) |
| PDF Bookmarks | PDF-specific, HTML has TOC with anchors |
| CSV Export | PDF workflow-specific |
| Font Embedding | Different model - HTML uses CSS @font-face |
| Background PDF Underlays | Different model - HTML uses CSS background-image |

## Critical Path

1. **Features 1-2** (Paged Mode + FormatGenerator) are foundational blockers
2. **Branch B and C** can proceed in parallel immediately
3. **Branch A features 15-18** depend on 1-2 completing

## Key Technical Decisions

1. **Paged.js Integration**: Already included in templates, needs activation
2. **FormatGenerator**: Complete module exists, just needs wiring
3. **Template-Driven**: All features use Template::Toolkit
4. **Config Compatibility**: Reuses PDF config where applicable

## Verification Strategy

Each feature includes:
- Manual verification steps
- Unit test file specification
- Expected assertions

Tests use real `.cho` input files (not mocks) per project convention.

## Files Changed

| File | Features |
|------|----------|
| `lib/ChordPro/Output/HTML5.pm` | 1, 2, 4, 5, 10, 11, 12, 13, 15, 17, 18 |
| `lib/ChordPro/Output/ChordProBase.pm` | 3 (rechorus dispatch) |
| `lib/ChordPro/Output/ChordDiagram/SVG.pm` | 14 (keyboard diagrams) |
| `lib/ChordPro/res/templates/html5/css/*.tt` | 6, 7, 8, 9, 12, 13 |
| `lib/ChordPro/res/templates/html5/paged/*.tt` | 1, 2, 15, 16, 17 |

## Next Steps

1. Implement Features 1-2 (critical blockers)
2. Start Branch B and C in parallel
3. Complete Branch A sequential features
4. Run `make test` after each feature
5. Visual verification in browser for CSS features

---

**Reference**: See `HTML5_PRINT_Missing_Features.xml` for complete implementation details, risks, and verification steps for each feature.
