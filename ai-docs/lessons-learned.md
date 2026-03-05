# Lessons Learned

Extracted from DONE items during `/archive` and `/update` passes.
Format: **L-N** (YYYY-MM-DD, item-ID): Lesson text.

---

## Technologie

- **L-1** (2026-02-11, item-20): Bundle output should be written directly by the backend to avoid the standard single-file output path; delegating to the normal writer loses control of file placement.
- **L-2** (2026-02-11, item-23): Shared layout/content templates keep bundled and inline paged output consistent with fewer moving parts than separate template trees.
- **L-3** (2026-02-11, item-21): Normalize HTML output before line splitting to prevent writer joins from reintroducing extra whitespace that was trimmed earlier.
- **L-25** (2026-02-26, item-48): Centralize delegate width resolution to keep pagewidth forwarding deterministic across handlers.
- **L-26** (2026-02-26, item-49): Delegate payload handling must support multiple SVG documents rather than assuming a single root graphic.
- **L-27** (2026-02-26, item-50): Split SVG fragments are separate documents, so shared CSS/font rules must be replicated per fragment.
- **L-28** (2026-02-26, item-51): A local style block can be partial; merge shared and local styles to prevent class/font regressions.

- **L-32** (2026-03-01, item-54): Parity improvements are more stable when renderer emits semantic metadata first and CSS consumes it, instead of hardcoding symbol-specific spacing rules.
- **L-33** (2026-03-01, item-55): For strum rows, canonical semantic names (`dn`/`up`) should drive rendering decisions, not display glyphs from font-dependent chord output.
- **L-41** (2026-03-01, item-59): When renderer paths handle mixed token payload types (strings + chord objects), all label emission points must use shared normalization helpers instead of direct string interpolation.
- **L-51** (2026-03-04, item-69): Legacy backends should normalize restricted-hash data into plain hashes before applying defaults.
- **L-52** (2026-03-04, item-70): Delegate helpers relying on module-scoped state should avoid local variable shadowing and guard backend-key access defensively.

## Architektur

- **L-4** (2026-02-11, item-19): Dedicated break elements between songs avoid leading blank pages and behave more consistently than relying on CSS break-before on the song wrapper itself.
- **L-5** (2026-02-11, item-18): Chord-only alignment depends on consistent flex item alignment across both standard and paged CSS templates; fixing only one template leaves the other misaligned.
- **L-6** (2026-02-12, item-31): When paged output relies on margin boxes, ensure the paged CSS template is selected even when configs omit paged templates — otherwise the @page rules that control margin content are never emitted.

- **L-9** (2026-02-24, item-38): `chordpro.json` has two `html5 { }` top-level blocks. JSON::Relaxed uses last-wins (not deep merge), so the second block completely replaces the first. New html5 config keys must be added to the SECOND block.
- **L-10** (2026-02-24, item-38): `make resources` skips Data.pm regeneration when it is newer than `chordpro.json`. Run `perl script/cfgboot.pl lib/ChordPro/res/config/chordpro.json -o lib/ChordPro/Config/Data.pm` directly to force-regenerate.
- **L-11** (2026-02-25, item-37): Backend-specific delegate overrides can be introduced with dotted config keys (e.g. html.handler/html5.handler/pdf.handler) while keeping generic handler defaults for compatibility.
- **L-12** (2026-02-25, item-37): When parser-time assets are compared structurally in tests, adding metadata fields such as delegate_type requires explicit expected-structure updates.
- **L-21** (2026-02-26, item-38): When config documents permit duplicate top-level keys, treat them as last-wins replacements and add new keys to the final occurrence.
- **L-22** (2026-02-26, item-45): Row-to-row layout parity requires shared geometry; hidden placeholders preserve alignment better than dropping structural nodes.
- **L-23** (2026-02-26, item-46): Scope two-column right-panel layout to a dedicated wrapper to avoid title/metadata interactions with grid sizing.

- **L-29** (2026-03-01, item-52): Panel sizing constraints must be applied on the element that owns background/border (`.cp-chord-diagrams`), otherwise wrapper-level fit-content rules can still yield full-width visual boxes.
- **L-30** (2026-03-01, item-52): When adding a flow-specific layout (top wrap), introducing a dedicated structural wrapper keeps right/top variants isolated and easier to reason about.
- **L-35** (2026-03-01, item-56): For strumline `~` semantics, parser output uses split chord parts with empty segments (`<EMPTY>`), so connector/pause logic should be derived from part adjacency and empties rather than raw source text.
- **L-39** (2026-03-01, item-58): Delegate modules shared across backends must guard backend-specific APIs (e.g., PDF XO internals) and provide deterministic fallback behavior.
- **L-40** (2026-03-01, item-58): Module-level imports should avoid package-scope ambiguity; fully qualified utility calls improve reliability across load paths.
- **L-43** (2026-03-04, item-60): Barline geometry from shared row-independent model; compact connected-pair styling asserted via arrow-stem geometry.
- **L-44** (2026-03-04, item-61): Normalize token semantics before rendering; shared decoration helpers reduce drift.
- **L-45** (2026-03-04, item-63): Row-type-aware column counting is the correct abstraction: strumline = beats (1 column), gridline = individual chords (N columns).
- **L-46** (2026-03-04, item-64): Semantic preservation and geometry normalization must remain separate concerns. Renderer-level handling safer than globally deleting in shared normalization.
- **L-47** (2026-03-04, item-65): Facade + internal module split reduces change risk while keeping external call-sites stable.
- **L-49** (2026-03-04, item-67): Namespace/path refactors safest with compatibility shim retained during migration.
- **L-50** (2026-03-04, item-68): Centralizing asset preparation simplifies downstream element handling.

## Testing

- **L-7** (2026-02-11, item-22): Keeping preview styles (screen mode) aligned with print defaults avoids visual surprises during development and review.
- **L-8** (2026-02-12, item-33): TOC entry class assertions should allow additional classes introduced by pagination features; assert on presence of the expected class rather than exact class-string equality.
- **L-13** (2026-02-25, item-39): When assertion intent changes from structural embedding to rendering semantics, update test plans and assertions together to avoid false failure from stale planned test counts.
- **L-14** (2026-02-25, item-39): Using the existing render_image/data-URI path for SVG keeps behavior consistent with non-SVG image handling and minimizes maintenance surface.
- **L-15** (2026-02-25, item-40): Extended tests that validate optional/legacy artifacts should gate on artifact presence and report SKIP rather than hard-fail.
- **L-16** (2026-02-25, item-40): Using FindBin/File::Spec for absolute path derivation in tests avoids cwd-dependent behavior caused by helper modules that chdir during import.
- **L-17** (2026-02-25, item-41): When converting text payloads to binary transport encodings (Base64), enforce explicit character-to-octet conversion at the boundary.
- **L-18** (2026-02-25, item-41): Mirrored regression suites (`t/html5/09_bugfixes.t` and `t/190_html5_bugfixes.t`) should both include new edge-case assertions to keep duplicate test tracks aligned.
- **L-19** (2026-02-25, item-42): Delegate payload normalization should enforce format contracts at backend boundaries (e.g., `<img>` with image/svg+xml requires SVG document payload, not arbitrary HTML wrapper markup).
- **L-20** (2026-02-25, item-42): For textual SVG payloads, URL-encoded UTF-8 data URIs provide a clear, standards-friendly representation and avoid unnecessary base64 inflation.
- **L-24** (2026-02-26, item-47): Warning-cleanup fixes should include explicit no-warning assertions to keep diagnostic signal quality stable.

- **L-31** (2026-03-01, item-54): Attribute-order assumptions in regex assertions are brittle; use order-independent lookaheads for HTML attribute checks.
- **L-34** (2026-03-01, item-55): Mirrored bugfix suites are effective guardrails for parity-sensitive HTML5 rendering changes and should be updated in lockstep.
- **L-36** (2026-03-01, item-56): Mirrored HTML5 bugfix suites remain essential for parity-sensitive rendering changes; update both in lockstep to prevent drift.
- **L-37** (2026-03-01, item-57): For parity-sensitive HTML5 rendering changes, assertions should validate structural SVG properties (geometry/text nodes/viewBox) rather than brittle encoded payload literals.
- **L-38** (2026-03-01, item-57): When mirrored suites exist, update them in lockstep to avoid divergence and false negatives.
- **L-42** (2026-03-01, item-59): Mirrored regression suites are effective to lock bugfix behavior and prevent one-sided test drift in HTML5 rendering changes.

## Security

## Process

- **L-48** (2026-03-04, item-66): Debugger-specific friction handled with local debugging practices, not by expanding public setter APIs.
