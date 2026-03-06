# plan_manager Cheat Sheet

Fast commands for daily XML lifecycle operations.

## Validate First

```bash
python3 ai-docs/plan_manager.py --json validate
```

## Create Item

```bash
python3 ai-docs/plan_manager.py --json create-item \
  --kind feature \
  --title "Short title" \
  --justification "Why needed"
```

## Approve / Start / Submit / Pass

```bash
python3 ai-docs/plan_manager.py --json transition --item-id 71 --to-status APPROVED --role PO --action approved
python3 ai-docs/plan_manager.py --json transition --item-id 71 --to-status IN_PROGRESS --role SM --action started
python3 ai-docs/plan_manager.py --json transition --item-id 71 --to-status REVIEW --role DEV --action submitted
python3 ai-docs/plan_manager.py --json transition --item-id 71 --to-status DONE --role TST --action passed --outcome DONE
```

## Fail + Follow-up Bug

```bash
python3 ai-docs/plan_manager.py --json transition \
  --item-id 71 \
  --to-status FAILED \
  --role TST \
  --action failed \
  --create-followup-bug-title "Follow-up bug for item 71"
```

## Archive Run

```bash
python3 ai-docs/plan_manager.py --json archive-run --role SM
```

## Structural Entries

```bash
python3 ai-docs/plan_manager.py --json create-structural --kind sprint --title "Sprint N" --scope-item 71
python3 ai-docs/plan_manager.py --json create-structural --kind release --title "Release vX.Y" --release-type MINOR --target-date 2026-03-31
python3 ai-docs/plan_manager.py --json create-structural --kind blocker --title "CI blocked" --severity HIGH --scope-item 71
```

## Translate Requirement

```bash
python3 ai-docs/plan_manager.py --json translate --requirement-id 80 --features 3
```

## Security Update

```bash
python3 ai-docs/plan_manager.py --json security-update \
  --title "Security review" \
  --description "What was reviewed" \
  --mitigation "What mitigates the risk"
```

## Sync Update

```bash
python3 ai-docs/plan_manager.py --json sync-update --summary "Grouped update summary"
```

## Fixture Mode (Safe Testing)

```bash
python3 ai-docs/plan_manager.py --json \
  --plan ai-docs/testing/xml-fixtures/overview-features-bugs.sample.xml \
  --archive ai-docs/testing/xml-fixtures/overview-features-bugs-archive.sample.xml \
  --overview ai-docs/testing/xml-fixtures/overview.sample.xml \
  --lessons ai-docs/testing/xml-fixtures/lessons-learned.sample.md \
  validate
```

## Final Checks

```bash
python3 ai-docs/plan_manager.py --json validate
xmllint --noout ai-docs/overview-features-bugs.xml
xmllint --noout ai-docs/overview-features-bugs-archive.xml
xmllint --noout ai-docs/overview.xml
```
