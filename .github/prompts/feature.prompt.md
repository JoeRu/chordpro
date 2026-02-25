---
description: 'Create a feature item in the implementation plan with optional modifiers.'
name: 'Create feature item'
argument-hint: 'Feature description with optional modifiers.'
agent: 'agent'
---
<!-- GENERATED FILE — do not edit directly.
     Source:   .claude/commands/feature.md
     Metadata: scripts/copilot-headers.json
     Regenerate: python3 scripts/generate-copilot-prompts.py -->

Create a **feature, epic, enabler, or requirement item** in the implementation plan. Item creation includes inline DA enrichment — the user sees a fully-planned item and only needs to `/approve` to proceed.

**Arguments:** `$ARGUMENTS` (description with optional modifiers)

## Phase 1 – Item Creation

1. **Read** `ai-docs/overview.xml` and `ai-docs/overview-features-bugs.xml` in parallel.
2. **Parse** the description from `$ARGUMENTS`. Extract optional modifiers:
   - `!critical`, `!high`, `!medium`, `!low` → override priority (default: MEDIUM)
   - `!security` → mark as security-relevant
   - `@<ID>` → set `depends-on`
   - `^<ID>` → set `parent` (sub-item of epic)
   - `--epic` → create as `type="epic"` (XL complexity, no tasks, has acceptance-criteria)
   - `--enabler` → create as `type="enabler"` (add `mapped-to-feature` if `^<ID>` provided)
   - `--requirement` → create as `type="requirement"` (raw user need — skip Phase 2; suggest `/translate` after)
   - `!run` → short-path: auto-approve after enrichment and execute immediately (see Phase 3)
3. **Search** existing items for duplicates. If found: inform user, update if needed; stop.
4. **Create the skeleton item**: `status="PENDING"`, default `priority="MEDIUM"`, next sequential ID, estimated complexity.
5. **Update `<changelog>`** and write the item to XML.

## Phase 2 – DA Enrichment (inline, before showing the item to the user)

Skip this phase for `--epic` (XL items must be decomposed first via `/translate`) and `--requirement` types.

6. **Read source files in parallel** — files referenced by related features in `overview.xml` and any files matching the item's domain. Never form technical opinions before reading.
7. **Consult** `ai-docs/lessons-learned.md` if it exists — identify applicable L-N IDs for this domain.
8. **Populate `<tasks>`** — concrete, ordered `<task>` entries; each completable by one developer in ≤ 1 day.
9. **Populate `<technical-parameters>`**:
   - `<constraint>` — hard limits (performance, memory, compatibility, licensing)
   - `<nfr type="performance|reliability|scalability|maintainability">` — measurable NFRs
   - `<pattern>` — recommended approach; cite applicable L-N lesson IDs here
10. **Populate `<verification>`** — `<tests>` with concrete, runnable test specifications.
11. **Security assessment** — evaluate AUTH, INPUT, DATA, NETWORK, CRYPTO, ACCESS, DISCLOSURE:
    - If `!security` modifier or any category applies: set `security="true"`, populate `<security-impact>` with `<category>`, `<threat>`, `<mitigation>`
    - Note the evaluation outcome even when no categories apply
12. **Impact check**: identify existing features potentially affected. Warn if any have `completeness != FULL` or `test-coverage == NONE`.
13. **If ENABLER items are needed** (technical prerequisites missing): note them for the user; create them only if clearly required.
14. **Collision analysis** — populate `<affected-files>` and enforce resource sequencing:
    a. List every project source file this item will **modify** or **delete** (exclude files it only reads or creates new).
    b. Write `<affected-files planned="true">` in the item XML, tagging each file with `role="modify|create|delete|read"` and `test="true"` for test files.
    c. Read `overview-features-bugs.xml`; collect `planned-files` of all `<item-ref>` entries with `status="APPROVED"` or `status="IN_PROGRESS"`.
    d. For each source file with `role="modify"` or `role="delete"`: check for overlap with those `planned-files`.
    e. **Hard conflict** (same source file, non-test):
       - Other item `IN_PROGRESS` → auto-set `depends-on={ID}` on this item; report: `"⚠ Resource conflict with item {ID} (IN_PROGRESS): {file}. depends-on set automatically."`
       - Other item `APPROVED` → set `depends-on={ID}` (lower-ID runs first unless priority warrants override); report conflict and reason.
    f. **Test-file overlap** → warn only: `"ℹ Same test file as item {ID}: {file}. Parallel execution possible but check for function-name collisions."`
    g. **Same-directory overlap** (different files, same module path) → soft warn only.
    h. Write space-separated non-test `modify`/`delete` file paths as `planned-files="{...}"` in the `<item-ref>` in the index.

## Phase 3 – Auto-run (only when `!run` modifier is present)

Skip this phase when `!run` is not set — the item stays `status="PENDING"` and waits for `/approve`.

After Phase 2 completes:

14. **Guard**: if complexity is `XL`, abort Phase 3 — set `status="PENDING"` and warn:
    `"!run is not allowed on XL items. Decompose first with /translate, then /run."`
15. **Auto-approve**: set `status="APPROVED"`. The `!run` modifier IS the user's explicit approval.
    - Generate branch name per the branch naming convention and set `<branch>`.
    - Add `<workflow-log>` entry: `role="PO" action="auto-approved" from-status="PENDING" to-status="APPROVED" note="!run short-path"`.
    - Update `<changelog>`.
16. **Announce**: `"Item N auto-approved via !run — executing..."`.
17. **Execute**: run the full `/run` logic for this item (Phases 2 and 3 of `run.md`).

## Output

**Without `!run`:** Display the complete enriched item for user review. The item stays `status="PENDING"` — run `/approve <ID>` to confirm and proceed to implementation.

**With `!run`:** Display enrichment summary, then proceed directly to execution output.

## Important

- Items stay PENDING until the user runs `/approve` **unless `!run` is set** — `!run` is the user's in-command approval
- `!run` is blocked on XL/epic items — these must be decomposed first
- XL items and epics (without `!run`): skip Phase 2; use `/translate <ID>` to decompose first
- Always search for duplicates before creating
- Keep XML valid at all times
