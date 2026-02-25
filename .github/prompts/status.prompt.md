---
description: 'Show the current status and details of a specific item.'
name: 'Item status'
argument-hint: 'Item ID.'
agent: 'agent'
---
<!-- GENERATED FILE — do not edit directly.
     Source:   .claude/commands/status.md
     Metadata: scripts/copilot-headers.json
     Regenerate: python3 scripts/generate-copilot-prompts.py -->

Show the **current status** of a specific item in the implementation plan.

**Arguments:** `$ARGUMENTS` (item ID)

## Steps

1. **Read** `ai-docs/overview-features-bugs.xml`.
2. **Find** the item with the given ID in the active section.
3. **If not found in active section**: read `ai-docs/overview-features-bugs-archive.xml` and search its `<archive>` block. If found there, display with a note: `[ARCHIVED on YYYY-MM-DD]`.
4. **If not found anywhere**: inform the user.
5. **Display** the item details:
   - ID, title, type, status, priority, complexity
   - Branch name (if APPROVED or later)
   - `depends-on` with status of each dependency
   - `parent` reference (if sub-item)
   - Tasks list with completion status
   - Security flag and impact (if applicable)
   - Verification/test plan
   - Result block `<r>` (if DONE or ARCHIVED)

## Output Format

```
Item {ID} "{title}"
  Type: {type} | Status: {status} | Priority: {priority} | Complexity: {complexity}
  Branch: {branch or "not yet assigned"}
  Depends on: {IDs with their statuses, or "none"}
  Parent: {parent ID or "none"}
  Security: {yes/no, categories if yes}
  Tasks: {completed}/{total}
    - [{done/pending}] {task description}
  Verification: {test count} tests planned
```

For archived items, prefix the output with `[ARCHIVED on YYYY-MM-DD]`.
