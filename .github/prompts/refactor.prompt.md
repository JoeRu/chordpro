---
description: 'Create a refactoring item in the implementation plan with optional modifiers.'
name: 'Create refactoring item'
argument-hint: 'Refactoring description with optional modifiers.'
agent: 'agent'
---
<!-- GENERATED FILE — do not edit directly.
     Source:   .claude/commands/refactor.md
     Metadata: scripts/copilot-headers.json
     Regenerate: python3 scripts/generate-copilot-prompts.py -->

Create a **refactoring item** in the implementation plan. Includes inline technical analysis so the user sees a fully-planned item before `/approve`.

**Arguments:** `$ARGUMENTS` (refactoring description with optional modifiers)

## Phase 1 – Item Creation

1. **Read** `ai-docs/overview.xml` and `ai-docs/overview-features-bugs.xml` in parallel.
2. **Parse** the description from `$ARGUMENTS`. Extract optional modifiers:
   - `!critical`, `!high`, `!medium`, `!low` → override priority (default: MEDIUM)
   - `!security` → mark as security-relevant
   - `@<ID>` → set `depends-on`
   - `^<ID>` → set `parent` (sub-item of epic)
   - `!run` → short-path: auto-approve after enrichment and execute immediately (see Phase 3)
3. **Search** existing items for duplicates. If found: inform user, update if needed; stop.
4. **Create the skeleton item**: `type="refactoring"`, `status="PENDING"`, `priority="MEDIUM"` (default), next sequential ID, estimated complexity.
5. **Update `<changelog>`** and write the item to XML.

## Phase 2 – DA Enrichment (inline, before showing to user)

6. **Read affected source files in parallel** — files identified from the description and related features in `overview.xml`.
7. **Consult** `ai-docs/lessons-learned.md` for applicable L-N IDs (refactoring patterns, architecture lessons).
8. **Populate `<justification>`** — describe the current problem and the structural improvement.
9. **Populate `<tasks>`** — concrete, ordered `<task>` entries; focus on safe, incremental steps that preserve behavior.
10. **Populate `<technical-parameters>`** — constraints (backward-compat, no behavior change), patterns (e.g., extract-method, dependency-inversion); cite relevant L-N IDs.
11. **Populate `<verification>`** — `<tests>` proving behavior is unchanged after refactoring; regression tests are especially important here.
12. **Security assessment** — refactoring can introduce regressions in security controls; evaluate all 7 categories.
13. **Impact check**: identify features that share the affected files; warn if `completeness != FULL` or `test-coverage == NONE`.
14. **Collision analysis** — populate `<affected-files>` and enforce resource sequencing:
    a. List every project source file this item will **modify** or **delete** (refactoring typically touches many files — list them all).
    b. Write `<affected-files planned="true">` in the item XML, tagging each file with `role="modify|create|delete|read"` and `test="true"` for test files.
    c. Read `overview-features-bugs.xml`; collect `planned-files` of all `<item-ref>` entries with `status="APPROVED"` or `status="IN_PROGRESS"`.
    d. For each source file with `role="modify"` or `role="delete"`: check for overlap with those `planned-files`.
    e. **Hard conflict** (same source file, non-test):
       - Other item `IN_PROGRESS` → auto-set `depends-on={ID}`; report: `"⚠ Resource conflict with item {ID} (IN_PROGRESS): {file}. depends-on set automatically."`
       - Other item `APPROVED` → set `depends-on={ID}` (lower-ID first); report conflict and reason.
    f. **Test-file overlap** → warn only.
    g. **Note:** refactoring items tend to have high collision rates — be thorough in step (a) to avoid undetected conflicts.
    h. Write space-separated non-test `modify`/`delete` file paths as `planned-files="{...}"` in the `<item-ref>` in the index.

## Phase 3 – Auto-run (only when `!run` modifier is present)

Skip this phase when `!run` is not set — the item stays `status="PENDING"` and waits for `/approve`.

After Phase 2 completes:

14. **Guard**: if complexity is `XL`, abort Phase 3 — set `status="PENDING"` and warn: `"!run is not allowed on XL items."`.
15. **Auto-approve**: set `status="APPROVED"`. The `!run` modifier IS the user's explicit approval.
    - Generate branch name per the branch naming convention and set `<branch>`.
    - Add `<workflow-log>` entry: `role="PO" action="auto-approved" from-status="PENDING" to-status="APPROVED" note="!run short-path"`.
    - Update `<changelog>`.
16. **Announce**: `"Item N auto-approved via !run — executing..."`.
17. **Execute**: run the full `/run` logic for this item (Phases 2 and 3 of `run.md`).

## Output

**Without `!run`:** Display the enriched item for user review. Stays `status="PENDING"` — run `/approve <ID>` to proceed.

**With `!run`:** Display enrichment summary, then proceed directly to execution output.

## Important

- Items stay PENDING until the user runs `/approve` **unless `!run` is set** — `!run` is the user's in-command approval
- `!run` is blocked on XL complexity items
- Refactoring tasks must be provably behavior-preserving — verification is critical
- Always search for duplicates first
- Keep XML valid at all times
