# Lessons Learned

Extracted from DONE items during `/archive` and `/update` passes.
Format: **L-N** (YYYY-MM-DD, item-ID): Lesson text.

---

## Technologie

- **L-1** (2026-02-11, item-20): Bundle output should be written directly by the backend to avoid the standard single-file output path; delegating to the normal writer loses control of file placement.
- **L-2** (2026-02-11, item-23): Shared layout/content templates keep bundled and inline paged output consistent with fewer moving parts than separate template trees.
- **L-3** (2026-02-11, item-21): Normalize HTML output before line splitting to prevent writer joins from reintroducing extra whitespace that was trimmed earlier.

## Architektur

- **L-4** (2026-02-11, item-19): Dedicated break elements between songs avoid leading blank pages and behave more consistently than relying on CSS break-before on the song wrapper itself.
- **L-5** (2026-02-11, item-18): Chord-only alignment depends on consistent flex item alignment across both standard and paged CSS templates; fixing only one template leaves the other misaligned.
- **L-6** (2026-02-12, item-31): When paged output relies on margin boxes, ensure the paged CSS template is selected even when configs omit paged templates — otherwise the @page rules that control margin content are never emitted.

- **L-9** (2026-02-24, item-38): `chordpro.json` has two `html5 { }` top-level blocks. JSON::Relaxed uses last-wins (not deep merge), so the second block completely replaces the first. New html5 config keys must be added to the SECOND block.
- **L-10** (2026-02-24, item-38): `make resources` skips Data.pm regeneration when it is newer than `chordpro.json`. Run `perl script/cfgboot.pl lib/ChordPro/res/config/chordpro.json -o lib/ChordPro/Config/Data.pm` directly to force-regenerate.

## Testing

- **L-7** (2026-02-11, item-22): Keeping preview styles (screen mode) aligned with print defaults avoids visual surprises during development and review.
- **L-8** (2026-02-12, item-33): TOC entry class assertions should allow additional classes introduced by pagination features; assert on presence of the expected class rather than exact class-string equality.
