---
description: 'Create a bug item in the implementation plan with optional modifiers.'
name: 'Create bug item'
argument-hint: 'Bug description with optional modifiers.'
agent: 'agent'
---
<!-- GENERATED FILE — do not edit directly.
     Source:   .claude/commands/bug.md
     Metadata: scripts/copilot-headers.json
     Regenerate: python3 scripts/generate-copilot-prompts.py -->

Create a **bug or problem item** in the implementation plan. Includes inline root-cause analysis and fix planning so the user sees a fully-analyzed item before `/approve`.

**Arguments:** `$ARGUMENTS` (description with optional modifiers)

## Phase 1 – Item Creation

1. **Read** `ai-docs/overview.xml` and `ai-docs/overview-features-bugs.xml` in parallel.
2. **Parse** the description from `$ARGUMENTS`. Extract optional modifiers:
   - `!critical`, `!high`, `!medium`, `!low` → override priority (default: HIGH for bugs)
   - `!security` → mark as security-relevant
   - `@<ID>` → set `depends-on`
   - `^<ID>` → set `parent` (sub-item of epic)
   - `--problem` → create as `type="problem"` (systemic/environmental issue, not a code defect)
   - `!run` → short-path: auto-approve after enrichment and execute immediately (see Phase 3)
3. **Search** existing items for duplicates. If found: inform user, update if needed; stop.
4. **Create the skeleton item**: `status="PENDING"`, `priority="HIGH"` (default), next sequential ID, estimated complexity.
   - For bugs: add `<steps-to-reproduce>`, `<expected-result>`, `<analysis>` with initial hypothesis from description
   - For problems: add `<justification>` describing the systemic issue and its impact
   - If `!security`: set `security="true"`, prefix title with `[SECURITY]`
5. **Update `<changelog>`** and write the item to XML.

## Phase 2 – DA Enrichment (inline bug analysis)

6. **Read suspected source files in parallel** — files related to the reported symptom, referenced features in `overview.xml`, and any files mentioned in the description.
7. **Enrich `<analysis>`** — add code-based hypotheses; update or confirm the initial hypothesis with evidence from the code.
8. **Populate `<tasks>`** — root-cause investigation steps + fix implementation steps.
9. **Populate `<verification>`** — `<tests>` that confirm the bug is fixed and no regressions are introduced.
10. **Security assessment** — if `!security` or any AUTH/INPUT/DATA/NETWORK/CRYPTO/ACCESS/DISCLOSURE category applies: populate `<security-impact>`.
11. **Impact check**: identify which existing features could be affected; warn if any have `completeness != FULL` or `test-coverage == NONE`.
12. **Collision analysis** — populate `<affected-files>` and enforce resource sequencing:
    a. List every project source file this item will **modify** or **delete** (exclude files it only reads or creates new).
    b. Write `<affected-files planned="true">` in the item XML, tagging each file with `role="modify|create|delete|read"` and `test="true"` for test files.
    c. Read `overview-features-bugs.xml`; collect `planned-files` of all `<item-ref>` entries with `status="APPROVED"` or `status="IN_PROGRESS"`.
    d. For each source file with `role="modify"` or `role="delete"`: check for overlap with those `planned-files`.
    e. **Hard conflict** (same source file, non-test):
       - Other item `IN_PROGRESS` → auto-set `depends-on={ID}`; report: `"⚠ Resource conflict with item {ID} (IN_PROGRESS): {file}. depends-on set automatically."`
       - Other item `APPROVED` → set `depends-on={ID}` (lower-ID first); report conflict and reason.
    f. **Test-file overlap** → warn only.
    g. Write space-separated non-test `modify`/`delete` file paths as `planned-files="{...}"` in the `<item-ref>` in the index.

## Phase 3 – Auto-run (only when `!run` modifier is present)

Skip this phase when `!run` is not set — the item stays `status="PENDING"` and waits for `/approve`.

After Phase 2 completes:

12. **Guard**: if `--problem` modifier is also set, abort Phase 3 — PROBLEM items require human review before action. Warn: `"!run is not allowed on PROBLEM items — review required."`. Keep `status="PENDING"`.
13. **Guard**: if complexity is `XL`, abort Phase 3 — set `status="PENDING"` and warn: `"!run is not allowed on XL items."`.
14. **Auto-approve**: set `status="APPROVED"`. The `!run` modifier IS the user's explicit approval.
    - Generate branch name per the branch naming convention and set `<branch>`.
    - Add `<workflow-log>` entry: `role="PO" action="auto-approved" from-status="PENDING" to-status="APPROVED" note="!run short-path"`.
    - Update `<changelog>`.
15. **Announce**: `"Item N auto-approved via !run — executing..."`.
16. **Execute**: run the full `/run` logic for this item (Phases 2 and 3 of `run.md`).

## Output

**Without `!run`:** Display the enriched bug item for user review. The item stays `status="PENDING"` — run `/approve <ID>` to proceed.

**With `!run`:** Display enrichment summary, then proceed directly to execution output.

## Important

- Items stay PENDING until the user runs `/approve` **unless `!run` is set** — `!run` is the user's in-command approval
- `!run` is blocked on PROBLEM items and XL complexity items
- PROBLEM items are for systemic issues (environment, process, architecture) — not code defects; skip Phase 2 for PROBLEM items
- Always search for duplicates first
- Keep XML valid at all times
