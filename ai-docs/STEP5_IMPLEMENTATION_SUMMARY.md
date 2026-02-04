# Step 5 Implementation Summary

**Date**: February 4, 2026  
**Task**: Add html.backend Config Option (Step 5 from changes-bugs.md)  
**Status**: ✅ COMPLETED

## Overview

Implemented configuration-driven backend selection for `.html` file output, allowing users to choose between legacy HTML and modern HTML5 backends via config file rather than command-line flags.

## What Was Done

### 1. Configuration Update
**File**: `lib/ChordPro/res/config/chordpro.json` (lines 1160-1172)

Added documentation for the `html.module` configuration option:
```json
html {
    // Backend module selection for .html files: "HTML" (legacy) or "HTML5" (modern).
    // When not specified, defaults to "HTML" for backward compatibility.
    // Use this to opt-in to modern HTML5 output without changing file extension.
    // This overrides the default backend after config is loaded.
    module: HTML
    styles {
        display : chordpro.css
        print   : chordpro_print.css
    }
}
```

**Key Discovery**: ChordPro already had this pattern implemented! Lines 197-200 of `lib/ChordPro.pm`:
```perl
if ( exists($config->{lc($options->{generate})})
     && exists($config->{lc($options->{generate})}->{module}) ) {
    $options->{generate} = $config->{lc($options->{generate})}->{module};
}
```

This means we just needed to document the feature - no code changes required.

### 2. Documentation Update
**File**: `.github/copilot-instructions.md` (Configuration System section)

Added new subsection documenting backend selection via config:
- Explains `html.module` option
- Provides usage example
- Notes precedence rules (CLI --generate overrides config)
- References implementation in ChordPro.pm

### 3. Build System
Regenerated `lib/ChordPro/Config/Data.pm` via `make` to embed updated config.

## Testing

### Manual Verification

**Test 1 - Default (Legacy HTML)**:
```bash
perl -Ilib script/chordpro.pl t/basic01.cho -o /tmp/test_default.html
```
✅ Output uses legacy HTML backend (table-based layout)

**Test 2 - HTML5 via Config**:
```bash
echo '{"html": {"module": "HTML5"}}' > /tmp/config.json
perl -Ilib script/chordpro.pl --config=/tmp/config.json t/basic01.cho -o /tmp/test_html5.html
```
✅ Output uses HTML5 backend (semantic HTML with `cp-` class prefixes)

**Test 3 - HTML5 Direct (Baseline)**:
```bash
perl -Ilib script/chordpro.pl --generate=HTML5 t/basic01.cho -o /tmp/test_direct.html
```
✅ Output identical to Test 2 (config selection works correctly)

### Automated Testing
```bash
make test
```
✅ All 108 tests pass (Files=108, Tests=2998)
- No regressions
- Both HTML and HTML5 backends functional
- Backward compatibility maintained

## Design Rationale

### Why `module` instead of `backend`?

Initially planned to add a new `html.backend` config key, but discovered:
1. ChordPro.pm already implements module-based backend override (lines 197-200)
2. Pattern used consistently across all output formats
3. Same mechanism that allows PDF.module, LaTeX.module, etc.

**Benefit**: Leverages existing, tested code path rather than introducing new pattern.

### Backward Compatibility

Default remains "HTML" (legacy), so:
- Existing workflows unaffected
- Users opt-in to HTML5 explicitly
- Migration can happen gradually

## Files Modified

1. `lib/ChordPro/res/config/chordpro.json` - documented html.module
2. `lib/ChordPro/Config/Data.pm` - regenerated (embedded config)
3. `.github/copilot-instructions.md` - added backend selection docs
4. `ai-docs/changes-bugs.md` - updated implementation status

## Impact

**Code Changes**: Minimal (documentation only)  
**Test Impact**: None (all existing tests pass)  
**User Impact**: Positive (new opt-in feature, no breaking changes)  
**Complexity**: Low (reuses existing pattern)

## Usage Example

Users wanting HTML5 output for `.html` files can now create a config file:

**myconfig.json**:
```json
{
  "html": {
    "module": "HTML5"
  }
}
```

Then use it:
```bash
chordpro --config=myconfig.json songs/*.cho -o songbook.html
```

Output will use modern HTML5 backend (semantic HTML, CSS custom properties, responsive design).

## Next Steps

- **Step 6**: Merge HTML5Paged into HTML5 (MAJOR REFACTORING - 4-6 hours)
  - Requires design decision on responsive-by-default approach
  - Affects 1500+ lines of code across two backends
  - Should be separate focused session

- **Step 7**: Update tests for Step 6 changes (~1 hour)
- **Step 8**: Complete user documentation (~1 hour)

## Lessons Learned

1. **Check existing patterns first**: The module-based backend selection already existed; we just needed to document it.

2. **Config timing matters**: Backend selection from file extension happens before config load (lines 125-151), but config can override it after load (lines 197-200).

3. **Test early, test often**: Manual testing with actual .cho files quickly revealed the HTML5 backend was working correctly.

4. **Documentation is implementation**: Sometimes the "implementation" is just making existing features discoverable.

## Related Documentation

- Implementation plan: `ai-docs/changes-bugs.md` (Steps 5)
- Merge summary: `ai-docs/MERGE_SUMMARY_20260204.md`
- Developer guide: `.github/copilot-instructions.md`
