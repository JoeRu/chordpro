# Paged.js analytics and usage

Scope: This summarizes how Paged.js is wired up in the Aurorae sample and what the experiments directory provides, based on the local files.

## Aurorae sample (testing/aurorae)

Key entry points:
- HTML entry file: [testing/aurorae/index.html](testing/aurorae/index.html)
- Book styling: [testing/aurorae/style-book.css](testing/aurorae/style-book.css)
- Paged.js screen/preview styles: [testing/aurorae/paged-js/asset-pagedjs.css](testing/aurorae/paged-js/asset-pagedjs.css)
- Paged.js print layout styles: [testing/aurorae/paged-js/layout-pagedjs.css](testing/aurorae/paged-js/layout-pagedjs.css)

Paged.js integration and layout patterns:
- Loads `paged.polyfill.js` directly in the page head (local dev URL). This is the only script dependency for pagination. See [testing/aurorae/index.html](testing/aurorae/index.html).
- Uses `@page` with size/margins plus left/right page variants, running headers, and counters. See [testing/aurorae/paged-js/layout-pagedjs.css](testing/aurorae/paged-js/layout-pagedjs.css).
- Runs page group layouts for frontmatter, parts, chapters, and blank pages using named pages (`page: frontmatter`, `page: chapter`, `@page:blank`). See [testing/aurorae/paged-js/layout-pagedjs.css](testing/aurorae/paged-js/layout-pagedjs.css).
- Uses `string-set` + `position: running()` for running headers, with `@top-center`/`@top-left`/`@top-right` margin boxes. See [testing/aurorae/paged-js/layout-pagedjs.css](testing/aurorae/paged-js/layout-pagedjs.css).
- TOC uses `target-counter(attr(href), page)` to insert page numbers for links. See [testing/aurorae/paged-js/layout-pagedjs.css](testing/aurorae/paged-js/layout-pagedjs.css).
- Break control is driven from CSS (`break-before`, `break-after`) in frontmatter and part sections. See [testing/aurorae/paged-js/layout-pagedjs.css](testing/aurorae/paged-js/layout-pagedjs.css).
- Screen preview uses `.pagedjs_pages` flex layout plus a baseline grid overlay for visual alignment checks (screen only). See [testing/aurorae/paged-js/asset-pagedjs.css](testing/aurorae/paged-js/asset-pagedjs.css).
- `style-book.css` focuses on typographic styling, counters for parts/chapters/appendices/plates, and frontmatter styling; it does not include Paged.js hooks, but pairs with the Paged.js print rules in layout-pagedjs.css. See [testing/aurorae/style-book.css](testing/aurorae/style-book.css).


## Experiments catalog (testing/experiments)

Top-level index: [testing/experiments/readme.md](testing/experiments/readme.md)

Lifecycle patterns seen in the experiments:
- Pre-pagination generation using `window.PagedConfig.before` (e.g., book index, baseline snap).
- Paged.js handlers via `Paged.Handler` hooks (`beforeParsed`, `afterPageLayout`, `afterRendered`) for layout-time transforms.
- Pure DOM utilities (e.g., smart quotes) that can run before or after pagination.

Selected experiment details and how they use Paged.js:
- Baseline grid snapping: Uses `snapBaseline()` plus `FontMetrics.js` to re-compute line-height/margins/padding and optionally draw a baseline grid. For Paged.js, it is invoked from `window.PagedConfig.before` so it runs before pagination. See [testing/experiments/baseline/README.md](testing/experiments/baseline/README.md) and [testing/experiments/baseline/js/snap-text-baseline.js](testing/experiments/baseline/js/snap-text-baseline.js).
- Book index: `createIndex()` builds an index from `data-book-index` spans and requires running before pagination; page numbers are inserted via CSS `target-counter`. See [testing/experiments/book-index/README.md](testing/experiments/book-index/README.md) and [testing/experiments/book-index/js/createIndex.js](testing/experiments/book-index/js/createIndex.js).
- Table of content: `createToc()` is called in a `beforeParsed` handler to collect title elements, create anchors, and emit a TOC list; page numbers are handled by CSS in the example stylesheet. See [testing/experiments/table-of-content/README.md](testing/experiments/table-of-content/README.md) and [testing/experiments/table-of-content/js/createToc.js](testing/experiments/table-of-content/js/createToc.js).
- Margin notes: `marginNotes` registers a handler that inserts call markers in `beforeParsed`, then positions notes in `afterPageLayout` with overflow detection and per-page left/right positioning based on margins. See [testing/experiments/margin-notes/README.md](testing/experiments/margin-notes/README.md) and [testing/experiments/margin-notes/marginNotes.js](testing/experiments/margin-notes/marginNotes.js).
- Sidenotes: `sidenote` handler creates per-page sidenote areas and relocates `.sidenote` elements into those areas in `afterRendered`. See [testing/experiments/sidenotes/README.md](testing/experiments/sidenotes/README.md) and [testing/experiments/sidenotes/sidenotes.js](testing/experiments/sidenotes/sidenotes.js).
- Notes via float areas: `notesFloat` builds a notes area with float-based positioning and moves note elements after rendering. See [testing/experiments/notes-float/README.md](testing/experiments/notes-float/README.md) and [testing/experiments/notes-float/js/floatNotes.js](testing/experiments/notes-float/js/floatNotes.js).
- Ordered list numbering: `noteNumbering()` assigns `data-item-num`, and `addingNumToOl()` restores `start` on the first `li` for lists split by pagination. See [testing/experiments/orderedList/js/orderedList.js](testing/experiments/orderedList/js/orderedList.js).
- Smart quotes: `smartquotes` is a bundled library that replaces neutral quotes with typographic ones; it can run pre- or post-pagination depending on desired behavior. See [testing/experiments/smartQuotes/js/smartquote.js](testing/experiments/smartQuotes/js/smartquote.js).
- Column float helper: `shift()` marks floating quotes as left or right column based on offset vs page center. See [testing/experiments/columnsAndFloat/js/quoteLocation.js](testing/experiments/columnsAndFloat/js/quoteLocation.js).
- Reuse page: An `afterRendered` handler clones existing rendered pages into a target container (proof-of-concept for reuse/spreads). See [testing/experiments/reuse-pages/README.md](testing/experiments/reuse-pages/README.md) and [testing/experiments/reuse-pages/js/reusePage.js](testing/experiments/reuse-pages/js/reusePage.js).
- Endnotes: README indicates a handler registered in `beforeParsed` for per-chapter numbering and back-links; implementation appears inline or external to the README. See [testing/experiments/endnotes/README.md](testing/experiments/endnotes/README.md).

Status signals from the experiments index:
- Marked as usable: bleeds, book index, columns-and-floats, drop-caps, ordered list, smart quotes, table of content.
- Marked experimental: endnotes, margin notes, repeating table header.
- Marked very experimental: chunker add page, notes float, sidenotes.
- Marked non-working: baseline (listed as needing rewrite).

## Notes and gaps
- Several experiments require pre-pagination hooks (`beforeParsed` or `window.PagedConfig.before`) to avoid DOM changes after pagination. This is consistent across baseline, book index, and TOC scripts.
- Notes-based layouts (margin notes, sidenotes) document a hard limitation: Paged.js does not split notes across pages, so overflow handling is manual or advisory.
- Aurorae’s TODO list overlaps with experiments (ordered list restarts, page-margin boxes, index) and could reuse scripts from the experiments directory.
- HTML5 paged output now emits section wrappers (cover/frontmatter/backmatter/toc/song) with `data-type` attributes, and paged CSS targets those section selectors to align with paged.js layout patterns.
