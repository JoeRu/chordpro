# Lessons Learned

> Auto-generated and maintained by the DA agent. Last updated: 2026-03-06.

## Technology

## Architecture

## Security

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

## Process

- **L-48** (2026-03-04, item-66): Debugger-specific friction handled with local debugging practices, not by expanding public setter APIs.
