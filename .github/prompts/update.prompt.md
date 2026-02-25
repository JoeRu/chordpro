---
description: 'Run code analysis in update mode to refresh XML overviews.'
name: 'Update overview'
argument-hint: 'No arguments.'
agent: 'agent'
---
<!-- GENERATED FILE — do not edit directly.
     Source:   .claude/commands/update.md
     Metadata: scripts/copilot-headers.json
     Regenerate: python3 scripts/generate-copilot-prompts.py -->

Run code analysis in **update mode** as described in `CLAUDE-implementation-plan-chapter.md`.

**Precondition:** Both `ai-docs/overview.xml` and `ai-docs/overview-features-bugs.xml` must already exist. If they don't, inform the user to run `/init` first.

## Steps

1. **Read** both XML files in parallel.
2. **Scan the codebase** (same analysis steps as `/init_overview`).
3. **Step 1 – Drift detection on `overview.xml`:**
   - Compare `<architecture>`, `<system-requirements>`, `<external-dependencies>`, `<interfaces>`, `<environments>`, `<security>` against current codebase
   - Update any mismatches in place
4. **Step 2 – Feature verification in `<completed-features>`:**
   - Verify `<file>` entries still exist for each `<feature>`
   - Check for new files belonging to existing features
   - Re-assess `completeness` and `test-coverage` attributes
   - Discover new features not yet in `overview.xml` → add them + create `[REF]` items if needed
   - Flag `STALE` features where `<file>` entries were deleted/renamed
5. **Step 3 – Item verification on `overview-features-bugs.xml`:**
   - Verify `<file>` references in `<r>` blocks still exist
   - Check `<depends-on>` and `parent` references are still valid
   - Flag stale items (PENDING/APPROVED for too long without progress)
6. **Step 4 – Report** your findings using this structure:

```xml
<drift-report date="YYYY-MM-DD">
  <summary>N overview.xml sections updated. N features verified (X OK, X changed, X STALE, X NEW). N item warnings.</summary>
  <changes>
    <change area="architecture|security|dependencies|..." description="What changed" />
  </changes>
  <feature-verification>
    <feature id="CF-N" status="OK|CHANGED|STALE|NEW" note="optional detail" />
  </feature-verification>
  <item-warnings>
    <warning item-id="N" reason="stale|broken-ref|..." />
  </item-warnings>
</drift-report>
```

7. **Update `<changelog>`** in `overview-features-bugs.xml`.

## Important

- Do NOT recreate the files from scratch – update them in place
- Keep XML valid
- Update `<metadata><updated>` in overview.xml
