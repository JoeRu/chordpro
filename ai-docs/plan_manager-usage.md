# Plan Manager Usage

This document explains how to use `ai-docs/plan_manager.py` to manage:
- `ai-docs/overview-features-bugs.xml`
- `ai-docs/overview-features-bugs-archive.xml`
- `ai-docs/overview.xml`
- `ai-docs/lessons-learned.md`

The tool is the central write backend for lifecycle mutations.

## Quick Start

Run from repository root:

```bash
python3 ai-docs/plan_manager.py --json validate
```

If the output contains `"ok": true` and no errors, XML state is consistent.

## Global Options

These options apply to all subcommands:

```bash
--plan <path>      # default: ai-docs/overview-features-bugs.xml
--archive <path>   # default: ai-docs/overview-features-bugs-archive.xml
--overview <path>  # default: ai-docs/overview.xml
--lessons <path>   # default: ai-docs/lessons-learned.md
--date YYYY-MM-DD  # default: today
--json             # machine-readable output
--dry-run          # no file writes
```

## Subcommands

### 1. `create-item`
Create lifecycle items (`feature`, `bug`, `refactoring`, `tech-debt`, `epic`, `enabler`, `requirement`, `security-item`).

Example:

```bash
python3 ai-docs/plan_manager.py --json create-item \
  --kind feature \
  --title "Add HTML5 regression diagnostics" \
  --justification "Improve failure triage speed" \
  --priority MEDIUM \
  --complexity M \
  --task "Add focused regression checks" \
  --test-file "t/html5/09_bugfixes.t"
```

### 2. `transition`
Apply status transitions and append workflow-log entries.

Example (`PENDING -> APPROVED`):

```bash
python3 ai-docs/plan_manager.py --json transition \
  --item-id 71 \
  --to-status APPROVED \
  --role PO \
  --action approved
```

Example (`REVIEW -> DONE` with result payload):

```bash
python3 ai-docs/plan_manager.py --json transition \
  --item-id 71 \
  --to-status DONE \
  --role TST \
  --action passed \
  --outcome DONE \
  --observations "Focused verification passed" \
  --lessons-text "Keep XML writes centralized" \
  --files lib/ChordPro.pm t/100_basic.t
```

Optional follow-up bug creation (`/fail` flow):

```bash
python3 ai-docs/plan_manager.py --json transition \
  --item-id 71 \
  --to-status FAILED \
  --role TST \
  --action failed \
  --create-followup-bug-title "Follow-up bug for failed item 71"
```

### 3. `archive-run`
Archive eligible DONE/DENIED items, rotate changelog, sync overview, and extract lessons.

```bash
python3 ai-docs/plan_manager.py --json archive-run --role SM
```

### 4. `create-structural`
Create sprint/release/blocker entries.

Sprint example:

```bash
python3 ai-docs/plan_manager.py --json create-structural \
  --kind sprint \
  --title "Sprint 4 - XML lifecycle hardening" \
  --scope-item 71
```

Release example:

```bash
python3 ai-docs/plan_manager.py --json create-structural \
  --kind release \
  --title "Release v3.2" \
  --release-type MINOR \
  --target-date 2026-03-31
```

Blocker example:

```bash
python3 ai-docs/plan_manager.py --json create-structural \
  --kind blocker \
  --title "CI pipeline blocked" \
  --severity HIGH \
  --resolution-plan "Unblock test environment" \
  --scope-item 71
```

### 5. `translate`
Translate `requirement` item into epic/features.

```bash
python3 ai-docs/plan_manager.py --json translate \
  --requirement-id 80 \
  --features 3
```

### 6. `init-overview`
Create missing XML skeleton files only.

```bash
python3 ai-docs/plan_manager.py --json init-overview
```

### 7. `sync-update`
Sync metadata timestamps and add grouped changelog summary.

```bash
python3 ai-docs/plan_manager.py --json sync-update \
  --summary "Update pass after code drift review"
```

### 8. `security-update`
Append/update security concern state in `overview.xml` and grouped changelog in plan XML.

```bash
python3 ai-docs/plan_manager.py --json security-update \
  --title "Path traversal review" \
  --description "Checked HTML5 asset path handling" \
  --mitigation "Validated canonical path constraints"
```

### 9. `validate`
Validate ID/status/dependency/changelog integrity.

```bash
python3 ai-docs/plan_manager.py --json validate
```

## Slash Command Mapping

- `/feature`, `/bug`, `/refactor`, `/debt` -> `create-item`
- `/approve`, `/deny`, `/plan-impl`, `/start`, `/submit`, `/pass`, `/fail` -> `transition`
- `/archive` -> `archive-run`
- `/release`, `/sprint`, `/blockers` -> `create-structural`
- `/translate` -> `translate`
- `/init_overview` -> `init-overview`
- `/update` -> `sync-update`
- `/security` -> `security-update`

## Safe Fixture Testing

To test without touching production XML files:

```bash
mkdir -p ai-docs/testing/xml-fixtures
cp ai-docs/overview-features-bugs.xml ai-docs/testing/xml-fixtures/overview-features-bugs.sample.xml
cp ai-docs/overview-features-bugs-archive.xml ai-docs/testing/xml-fixtures/overview-features-bugs-archive.sample.xml
cp ai-docs/overview.xml ai-docs/testing/xml-fixtures/overview.sample.xml
cp ai-docs/lessons-learned.md ai-docs/testing/xml-fixtures/lessons-learned.sample.md
```

Then run any command with explicit file options:

```bash
python3 ai-docs/plan_manager.py --json \
  --plan ai-docs/testing/xml-fixtures/overview-features-bugs.sample.xml \
  --archive ai-docs/testing/xml-fixtures/overview-features-bugs-archive.sample.xml \
  --overview ai-docs/testing/xml-fixtures/overview.sample.xml \
  --lessons ai-docs/testing/xml-fixtures/lessons-learned.sample.md \
  validate
```

## Recommended Post-Run Checks

```bash
python3 ai-docs/plan_manager.py --json validate
xmllint --noout ai-docs/overview-features-bugs.xml
xmllint --noout ai-docs/overview-features-bugs-archive.xml
xmllint --noout ai-docs/overview.xml
```

## Notes

- Keep grouped changelog entries concise per interaction.
- `archive-run` enforces main changelog length (`<= 30`) via rotation.
- Use `--json` for command orchestration and consistent parsing.
