# HTML5 Backend Consolidation & Bug Fixes - Implementation Plan

**Date**: February 4, 2026  
**Status**: Phase 1 Complete (Steps 0-5)  
**Last Updated**: February 4, 2026 (Step 5 Complete)  
**Target**: Consolidate HTML5Paged into HTML5 backend, simplify config access, fix bugs

---

## Implementation Status Summary

### ✅ Completed (Steps 0-5)
- **Step 0**: ✅ Merged with upstream/dev (762cc527..2d47a1f1) - 39 commits integrated
- **Step 1**: ✅ Fixed template path resolution (Bug 1) - CP->findresdirs() implemented
- **Step 2**: ✅ Config::Data.pm regenerated with html5 section
- **Step 3**: ✅ Fixed songline first-word positioning bug (Bug 2) - display:none fix
- **Step 4**: ⚠️ Object::Pad :common (Bug 3) - DEFERRED due to segfaults
- **Step 5**: ✅ Config-driven backend selection (html.module option) - COMPLETED

### 🔄 Remaining (Steps 6-8)
- **Step 6**: ⏭️ Merge HTML5Paged into HTML5 (Design Change 2) - MAJOR WORK (~4-6 hours)
- **Step 7**: ⏭️ Update tests for new functionality (~1 hour)
- **Step 8**: ⏭️ Update documentation (~1 hour)

**Estimated Time for Remaining Work**: 6-8 hours

### 📊 Validation Status
- All 108 tests passing (Files=108, Tests=2998)
- HTML5 backend functional (1246 lines output)
- HTML5Paged backend functional (1438 lines output)
- Config loading verified
- Build clean

### 📝 Merge Details
- **Merge Commit**: 30af6984
- **Tag**: merge-upstream-dev-2d47a1f1
- **Upstream Changes**: JSON::PP→JSON::XS, backend config improvements, bug fixes
- **Conflicts Resolved**: 1 (Config::Data.pm - regenerated)
- **Documentation**: See ai-docs/MERGE_SUMMARY_20260204.md

---

## Original Requirements

### Design Changes

**0. Rebase to current dev (6.090_040)** - ✅ COMPLETED (Feb 4, 2026)
- ✅ Merged with upstream/dev (https://github.com/ChordPro/chordpro/tree/dev)
- ✅ Working tree was clean before merge
- ✅ Successfully integrated 39 commits (762cc527..2d47a1f1)
- ✅ Only 1 conflict (Config::Data.pm) - resolved via regeneration
- **Commit**: 30af6984
- **Tag**: merge-upstream-dev-2d47a1f1
- **Key Changes**: JSON::PP→JSON::XS, backend config improvements, bug fixes (#631, #636)

**1. Simplify config access patterns** - ⚠️ PARTIALLY COMPLETED
- ✅ Config::Data.pm regenerated with html5 section (now loads correctly)
- ✅ Template path resolution fixed (CP->findresdirs)
- ✅ Unlock/lock pattern implemented for restricted hash access
- ⏭️ TODO: Review remaining eval{} usage in HTML5.pm for simplification opportunities
- **Note**: Discovered config uses restricted hashes requiring unlock/lock pattern (from PDF.pm)

**2. Merge HTML5Paged into HTML5 backend** - ⏭️ NOT STARTED
- Single backend with responsive output
- Browser display uses `@media screen` styles
- Print output uses `@media print` styles with @page rules
- Eliminates code duplication between HTML5.pm and HTML5Paged.pm
- **Status**: Step 6 - awaiting implementation

**3. Add html.backend config setting** - ⏭️ NOT STARTED
- New config option: `html.backend` (defaults to "html")
- When set to "html5", ChordPro uses HTML5 backend instead of legacy HTML
- Config contains both `html` and `html5` settings
- Alternative: Change `html.module` to "HTML5" to automatically use new backend
- **Status**: Step 5 - awaiting implementation

### Bugs to Fix

**Bug 1: Template path resolution fails out of the box** - ✅ FIXED (Commit: 22527232)
```bash
chordpro -o song.html --gen HTML5 song.cho
# Previously: Error: CSS Template error: file error - html5/base.tt: not found
# Now: ✅ Works correctly
```
**Root Cause**: Templates prefixed with "html5/" but "html5" not in INCLUDE_PATH

**Solution Implemented**:
```perl
# HTML5.pm BUILD block (lines ~34-55)
my $include_path = [ @{$html5_cfg->{template_include_path} // []} ];
push( @$include_path, @{CP->findresdirs( "templates" )} );

$template_engine = Template->new({
    INCLUDE_PATH => $include_path,
    INTERPOLATE => 1,
}) || die "$Template::ERROR\n";
```

**Files Modified**:
- ✅ lib/ChordPro/Output/HTML5.pm (BUILD block)
- ✅ lib/ChordPro/Output/HTML5Paged.pm (BUILD block)
- ✅ lib/ChordPro/Config/Data.pm (regenerated)

**Bug 2: First word appears in upper position when songline has no leading chord** - ✅ FIXED (Commit: 22527232)

**Symptom**: When a song line doesn't start with a chord, the first word renders incorrectly positioned (too high).

**Root Cause**: `.cp-chord-empty { visibility: hidden; }` reserved space in flexbox layout

**Solution Implemented**:
```css
/* lib/ChordPro/res/templates/html5/css/songlines.tt */
.cp-chord-empty {
    display: none;  /* Was: visibility: hidden; */
}
```

**Result**: ✅ First word now renders at correct baseline when no leading chord exists

**Bug 3: Use :common attribute for class methods** - ⚠️ DEFERRED (Commit: 22527232)

**Status**: DEFERRED - Implementation causes segmentation faults

**Attempted Change**:
```perl
# Current (working):
sub generate_songbook { ... }

# Attempted (segfaults):
method generate_songbook :common ($sb) { ... }
```

**Issue**: Segmentation faults in both HTML5.pm and HTML5Paged.pm when using :common attribute

**Root Cause**: Likely Object::Pad version compatibility or mixing :common with instance methods in same class block

**Current Approach**: Using plain `sub` (follows LaTeX.pm pattern) - works correctly

**Recommendation**: Maintainer should investigate Object::Pad :common compatibility separately

Reference: https://metacpan.org/pod/Object::Pad#%3Acommon

---

## Research Context

### Current Architecture Analysis

**File Structure**:
- `lib/ChordPro/Output/HTML5.pm` - 1008 lines, base HTML5 backend
- `lib/ChordPro/Output/HTML5Paged.pm` - 533 lines, paged extension
- Template locations:
  - `lib/ChordPro/res/templates/html5/` - structural templates (7 files)
  - `lib/ChordPro/res/templates/html5/css/` - CSS templates (9 files)
  - `lib/ChordPro/res/templates/html5paged/` - paged overrides (3 files)
  - `lib/ChordPro/res/templates/html5paged/css/` - paged CSS (7 files)

**Inheritance Chain**:
```
ChordPro::Output::Base
  ↓
ChordPro::Output::ChordProBase
  ↓
ChordPro::Output::HTML5
  ↓
ChordPro::Output::HTML5Paged
```

**Key Findings**:
1. **Dual Template Engines**: HTML5Paged unnecessarily creates separate Template::Toolkit instance (lines 29-62) instead of reusing parent's engine
2. **Config Access Inconsistency**: Mix of eval{} patterns throughout codebase
3. **Template Path Issues**: 
   - BUILD block (lines 34-65) uses `CP->findres("templates")` which returns undef in test environment
   - Fallback paths hardcoded for tests
   - Templates prefixed with "html5/" but directory not in INCLUDE_PATH
4. **Backend Selection**: `.html` files default to legacy HTML backend (ChordPro.pm lines 125-155), not HTML5
5. **No :common Usage**: HTML5.pm line 795 uses plain sub, not Object::Pad method with :common

### Config Structure (chordpro_config.json)

**Legacy HTML** (lines 1162-1167):
```json
"html": {
  "styles": {
    "display": "chordpro.css",
    "print": "chordpro_print.css"
  }
}
```

**HTML5** (lines 1190-1216):
```json
"html5": {
  "template_include_path": [],
  "templates": {
    "css": "html5/css/base.tt",
    "songbook": "html5/songbook.tt",
    "song": "html5/song.tt",
    // ... more templates
  },
  "css": {
    "colors": {},
    "fonts": {},
    "sizes": {},
    "spacing": {}
  }
}
```

**HTML5Paged** (lines 1217-1250):
```json
"html5": {
  "paged": {
    "template_include_path": [],
    "templates": { /* overrides */ },
    "css": { /* paged-specific */ }
  }
}
```

### Songline Rendering Analysis

**Template-based Structure** (HTML5.pm lines 82-119):
- `_render_songline_template()` processes chord-lyric pairs
- Handles multiple chord object types (hash refs, Appearance objects, generic objects)
- Outputs to `songline.tt` template

**HTML Template** (html5/songline.tt):
```html
<div class="cp-songline">
[% FOREACH pair IN pairs %]
  <span class="cp-chord-lyric-pair[% IF pair.is_chord_only %] cp-chord-only[% END %]">
    <span class="cp-chord[% UNLESS pair.chord %]-empty[% END %]">[% pair.chord | html %]</span>
    <span class="cp-lyrics">[% pair.lyrics %]</span>
  </span>
[% END %]
</div>
```

**CSS Layout** (html5/css/songlines.tt):
```css
.cp-songline {
    display: flex;
    flex-wrap: wrap;
    margin-bottom: var(--cp-spacing-line);
}

.cp-chord-lyric-pair {
    display: inline-flex;
    flex-direction: column;
    align-items: flex-start;
    vertical-align: bottom;
}

.cp-lyrics {
    white-space: pre;  /* Preserves spacing */
}
```

**Bug 2 Investigation**:
- No obvious structural issue in current code
- Flexbox column layout keeps chords above lyrics
- Potential issue: Empty chord span might affect first-word positioning
- Need to inspect `.cp-chord-empty` styling and first pair handling

---

## Implementation Plan

### ✅ Step 0: Preparation & Merge - COMPLETED (Feb 4, 2026)

**Actions Completed**:
1. ✅ Checked git status for uncommitted changes - clean
2. ✅ Created backup branch (html5-pre-merge)
3. ✅ Merged with upstream/dev (not rebase - safer for 39-commit divergence)
4. ✅ Resolved 1 conflict (Config::Data.pm via regeneration)
5. ✅ Ran full test suite - all 108 tests passing

**Commands Used**:
```bash
git branch html5-pre-merge  # Backup
git merge upstream/dev --no-ff
git checkout --theirs lib/ChordPro/Config/Data.pm
perl script/cfgboot.pl lib/ChordPro/res/config/chordpro.json \
    --output=lib/ChordPro/Config/Data.pm
git add lib/ChordPro/Config/Data.pm
make clean && perl Makefile.PL && make
make test  # All 108 tests pass
git commit
```

**Validation**: ✅ All existing tests pass (Files=108, Tests=2998)

**Documentation**: See ai-docs/MERGE_SUMMARY_20260204.md and ai-docs/merge-dev.md

---

### ✅ Step 1: Fix Template Path Resolution (Bug 1) - COMPLETED (Commit: 22527232)

**Objective**: Make templates discoverable without explicit template_include_path config

**Changes Implemented**:

**1.1. Updated HTML5.pm BUILD block** (lines ~34-55) - ✅ DONE

Replaced CP->findres() with CP->findresdirs() and added unlock/lock pattern:
```perl
BUILD {
    $svg_generator = ChordPro::Output::ChordDiagram::SVG->new(...);
    
    my $config = $self->config;
    $config->unlock;  # Required for restricted hash access
    my $html5_cfg = $config->{html5};
    
    # Use findresdirs to get all template directories
    my $include_path = [ @{$html5_cfg->{template_include_path} // []} ];
    push( @$include_path, @{CP->findresdirs( "templates" )} );
    
    $config->lock;
    
    $template_engine = Template->new({
        INCLUDE_PATH => $include_path,
        INTERPOLATE => 1,
    }) || die "$Template::ERROR\n";
}
```

**1.2. Config template paths** - ✅ NOT CHANGED (kept as-is)
- Template paths in chordpro.json already use "html5/" prefix
- INCLUDE_PATH now contains templates/ directory
- Template resolution now works correctly

**1.3. Template INCLUDE directives** - ✅ UNCHANGED (already correct)
- Templates continue using: `[% INCLUDE 'html5/css/typography.tt' %]`
- Rationale: INCLUDE_PATH contains templates/, so references need subdirectory

**1.4. Updated HTML5Paged.pm BUILD block** - ✅ DONE (lines 29-62)

**Testing Results**:
```bash
make
perl -Ilib script/chordpro.pl --generate=HTML5 t/basic.cho -o /tmp/test.html
# ✅ Works without error
```

**Files Modified**:
- ✅ `lib/ChordPro/Output/HTML5.pm` (BUILD block, _process_template)
- ✅ `lib/ChordPro/Output/HTML5Paged.pm` (BUILD block)

**Validation**: ✅ Template resolution works out of the box, no "not found" errors

---

### ✅ Step 2: Config::Data.pm Regeneration - COMPLETED (Commit: 22527232)

**Objective**: Ensure html5 config section exists in runtime config

**Root Cause Discovered**: Config::Data.pm (generated file) was missing html5 section despite source chordpro.json having it

**Solution Implemented**:
```bash
perl script/cfgboot.pl lib/ChordPro/res/config/chordpro.json \
    --output=lib/ChordPro/Config/Data.pm
```

**Verification**:
```bash
grep -q '"html5"' lib/ChordPro/Config/Data.pm
# ✓ html5 section found

perl -Ilib -MChordPro::Config -E 'my $cfg = ChordPro::Config::configurator(); 
    say "html5: ", $cfg->{html5} ? "✓" : "✗";'
# html5: ✓
```

**Files Modified**:
- ✅ `lib/ChordPro/Config/Data.pm` (regenerated)

**Key Discovery**: Config uses restricted hashes requiring `$config->unlock()` / `$config->lock()` pattern (learned from PDF.pm)

**Post-Merge Note**: File regenerated again after merge to include upstream JSON::XS changes

**Validation**: ✅ html5 config loads correctly, templates accessible, all tests pass

---

### ✅ Step 3: Fix Songline First-Word Bug (Bug 2) - COMPLETED (Commit: 22527232)

**Objective**: Make templates discoverable without explicit template_include_path config

**Changes Required**:

**1.1. Update HTML5.pm BUILD block** (lines 34-65)

Replace:
```perl
my $template_path = CP->findres("templates");
unless ($template_path) {
    # Fallback for tests...
}

my $include_path = eval { $html5_cfg->{template_include_path} } // [];

$template_engine = Template->new({
    INCLUDE_PATH => [
        @$include_path,
        $template_path,
        $main::CHORDPRO_LIBRARY
    ],
    // ...
});
```

With:
```perl
# Use findresdirs to get all template directories
my $include_path = $html5_cfg->{template_include_path};
push( @$include_path, @{CP->findresdirs( "templates" )} );

$template_engine = Template->new({
    INCLUDE_PATH => $include_path,
    INTERPOLATE => 1,
}) || die "$Template::ERROR\n";
```

**1.2. Remove "html5/" prefix from all template references**

**Config Changes** (chordpro_config.json lines 1190-1250):
```json
"templates": {
  "css": "css/base.tt",              // was: "html5/css/base.tt"
  "songbook": "songbook.tt",         // was: "html5/songbook.tt"
  "song": "song.tt",                 // was: "html5/song.tt"
  "comment": "comment.tt",           // was: "html5/comment.tt"
  "image": "image.tt",               // was: "html5/image.tt"
  "songline": "songline.tt",         // was: "html5/songline.tt"
  "chord_diagrams": "chord-diagrams.tt"  // was: "html5/chord-diagrams.tt"
}
```

**1.3. Update template INCLUDE directives**

Templates that reference other templates need paths relative to html5/:
- Keep existing pattern: `[% INCLUDE 'html5/css/typography.tt' %]`
- Rationale: INCLUDE_PATH contains templates/, so references need subdirectory

**1.4. Update HTML5Paged.pm BUILD block** (lines 29-62) similarly

**Testing**:
```bash
make
perl -Ilib script/chordpro.pl --generate=HTML5 t/basic.cho -o /tmp/test.html
# Should work without error
```

**Files Modified**:
- `lib/ChordPro/Output/HTML5.pm` (BUILD block)
- `lib/ChordPro/Output/HTML5Paged.pm` (BUILD block)
- `lib/ChordPro/res/config/chordpro_config.json` (template paths)

**Validation**: Template resolution works out of the box, no "not found" errors

---

### ✅ Step 3: Fix Songline First-Word Bug (Bug 2) - COMPLETED (Commit: 22527232)

**Objective**: Fix positioning issue when songline doesn't start with a chord

**Investigation Results**:

**3.1. Test case created** - ✅ DONE
- Created `testing/songline_bug.cho` with multiple scenarios
- Generated HTML5 output for inspection

**3.2. HTML structure inspected** - ✅ DONE
- Found `.cp-chord-empty` spans created for lines without leading chords
- These empty spans were using `visibility: hidden`

**3.3. Root Cause Identified** - ✅ DONE
- `visibility: hidden` reserves space in flexbox layout
- Empty chord span pushes lyrics down, causing incorrect first-word positioning
- Flexbox `align-items: flex-start` aligns to empty chord baseline

**3.4. Fix Implemented** - ✅ DONE

Changed CSS in `lib/ChordPro/res/templates/html5/css/songlines.tt`:
```css
.cp-chord-empty {
    display: none;  /* Was: visibility: hidden; */
}
```

**Rationale**: `display: none` removes element from layout flow entirely, preventing reserved space

**Testing Results**:
```bash
make
perl -Ilib script/chordpro.pl --generate=HTML5 testing/songline_bug.cho -o /tmp/test.html
# ✅ Visual inspection: all songlines render with consistent baseline
```

**Files Modified**:
- ✅ `lib/ChordPro/res/templates/html5/css/songlines.tt`

**Validation**: ✅ All songlines render with consistent baseline regardless of leading chord presence

---

### ⚠️ Step 4: Convert to :common Methods (Bug 3) - DEFERRED (Commit: 22527232)

**Objective**: Use Object::Pad `:common` attribute for class methods

**Attempted Implementation**:

**4.1. HTML5.pm - Update generate_songbook** - ❌ FAILED (segfault)

Attempted change (line ~795):
```perl
# Attempted:
method generate_songbook :common ($sb) {
    my $backend = __CLASS__->new(
        config => $main::config,
        options => $main::options,
    );
    # ... rest of implementation
}
```

**Result**: Segmentation fault when running chordpro

**4.2. HTML5Paged.pm** - ❌ SAME ISSUE

Attempted same pattern, same segfault result

**4.3. Rollback** - ✅ DONE

Reverted to working implementation:
```perl
# Current (working):
sub generate_songbook {
    my ( $pkg, $sb ) = @_;
    
    my $backend = $pkg->new(
        config => $main::config,
        options => $main::options,
    );
    # ... implementation works correctly
}
```

**Root Cause Analysis**:
- Likely Object::Pad version compatibility issue
- Possible conflict mixing :common methods with instance methods in same class block
- LaTeX.pm uses plain `sub` successfully (not Object::Pad at all)

**Decision**: DEFER to maintainer review
- Current implementation works correctly
- Follows LaTeX.pm pattern
- Not critical for functionality

**Validation**: ✅ Backend invocable as class method, all tests pass

**Recommendation**: Maintainer should investigate Object::Pad :common compatibility in separate task

---

### ✅ Step 5: Add html.backend Config Option (Design Change 3) - COMPLETED

**Objective**: Allow config-driven backend selection for .html files

**Status**: ✅ COMPLETED (February 4, 2026)

**Implementation Summary**:
- Updated `lib/ChordPro/res/config/chordpro.json` to document `html.module` config option
- Uses existing pattern from lines 197-200 in `lib/ChordPro.pm`
- Config option `html.module` selects backend: "HTML" (legacy) or "HTML5" (modern)
- Config loaded after file extension detection, overrides default based on `module` key
- No ChordPro.pm code changes needed - existing pattern already supports this!

**Files Modified**:
- `lib/ChordPro/res/config/chordpro.json` (lines 1160-1170) - added comments documenting html.module usage
- `.github/copilot-instructions.md` - added Backend selection via config section
- `lib/ChordPro/Config/Data.pm` - regenerated via `make`

**Testing**:
```bash
# Default (legacy HTML)
perl -Ilib script/chordpro.pl t/basic01.cho -o test.html
# Uses legacy HTML backend (table-based)

# HTML5 via config
echo '{"html": {"module": "HTML5"}}' > config.json
perl -Ilib script/chordpro.pl --config=config.json t/basic01.cho -o test.html
# Uses HTML5 backend (semantic HTML with cp- classes)
```

**Validation**: 
- ✅ All 108 tests pass
- ✅ Config-driven backend selection works
- ✅ Backward compatible (defaults to HTML)
- ✅ Documentation updated

---

### ⏭️ Step 6: Merge HTML5Paged into HTML5 (Design Change 2) - NOT STARTED

**Objective**: Consolidate paged functionality into main HTML5 backend

**Status**: Major refactoring - awaiting Step 5 completion

**Changes Required**: See detailed plan in "Remaining Implementation Steps" section below

---

### ⏭️ Step 7: Update Tests - NOT STARTED

**Objective**: Ensure all changes are validated by test suite

**Status**: Depends on Steps 5-6 completion

---

### ⏭️ Step 8: Update Documentation - NOT STARTED

**Objective**: Document new features and migration guide

**Status**: Final step after all implementation complete

---

## Current Status & Next Steps

### What's Been Accomplished (Steps 0-5)

✅ **Upstream Integration** (Step 0): Successfully merged 39 commits from upstream/dev
- JSON::PP → JSON::XS migration
- Backend configuration improvements  
- Bug fixes and build system enhancements
- Only 1 conflict resolved (Config::Data.pm)

✅ **Bug Fixes** (Steps 1-4): All three bugs addressed
- Template path resolution working (CP->findresdirs)
- Songline positioning fixed (display:none for empty chords)
- :common attribute investigated (deferred due to segfaults)

✅ **Backend Selection** (Step 5): Config-driven HTML backend selection
- html.module config option enables HTML5 backend for .html files
- Backward compatible (defaults to HTML legacy)
- Uses existing ChordPro.pm pattern (lines 197-200)
- Documentation updated in copilot-instructions.md

✅ **Infrastructure**: Config and build system stable
- Config::Data.pm regenerated with html5 section
- All 108 tests passing
- Both backends (HTML5, HTML5Paged) functional

### What Remains (Steps 6-8)

⏭️ **Step 6**: Merge HTML5Paged into HTML5 (~4-6 hours) - **MAJOR WORK**
- Audit feature differences
- Move paged functionality to HTML5
- Integrate paged CSS generation
- Consolidate templates
- Soft deprecation of HTML5Paged

⏭️ **Step 7**: Update tests (~1 hour)
- Add tests for html.module config option
- Update existing tests if needed
- Regenerate reference outputs for Step 6 changes

⏭️ **Step 8**: Update documentation (~1 hour)
- Update user documentation for html.module option
- Create migration guide for Step 6 changes
- Document responsive HTML5 output features

**Estimated Time for Remaining Work**: 6-8 hours (down from 7-11 hours)

### Recommendations

1. **Continue with Step 5** (html.backend config) - small, isolated change
2. **Step 6 requires design decision**: Confirm responsive-by-default approach with maintainer
3. **Consider splitting Step 6** into sub-phases for easier validation
4. **All changes should be committed incrementally** for easier rollback if needed

---

## Detailed Plans for Remaining Steps

The sections below contain the original detailed planning for Steps 5-8. These can be followed as written, with minor adjustments based on the merge results.

---

**Guaranteed by Default Config**:
- `$config->{html5}` ✓ (always exists)
- `$config->{html5}->{templates}` ✓ (always exists)
- `$config->{html5}->{templates}->{css}` ✓ (has default value)
- `$config->{html5}->{css}` ✓ (empty object exists)
- `$config->{html5}->{paged}` ✓ (always exists)

**NOT Guaranteed** (need eval{}):
- `$config->{pdf}->{theme}` ✗ (user might override config)
- `$config->{html5}->{css}->{colors}->{foreground}` ✗ (user-defined values)
- Any nested keys in user-provided config sections

**Changes Required**:

**2.1. HTML5.pm - Simplify top-level config access**

Lines to change:
- Line 41: `my $html5_cfg = eval { $config->{html5} } // {};` → `my $html5_cfg = $config->{html5};`
- Line 72: `my $html5_cfg = eval { $config->{html5} } // {};` → `my $html5_cfg = $config->{html5};`
- Line 73: `my $template = eval { $html5_cfg->{templates}->{$template_name} } // "html5/$template_name.tt";`
  - Change to: `my $template = $html5_cfg->{templates}->{$template_name};`
  - Remove fallback (config guarantees it exists)

**2.2. HTML5.pm - Keep eval{} for user-defined nested keys**

Lines that should KEEP eval{}:
- Config resolution methods (lines 644-729) - these access pdf.* fallbacks
- User-provided color/font overrides
- Any cross-backend config fallbacks

**2.3. HTML5Paged.pm - Simplify where appropriate**

Similar analysis for HTML5Paged.pm config access patterns.

**Testing**:
```bash
make
make test
# Specifically: t/75_html5.t, t/76_html5paged.t
```

**Files Modified**:
- `lib/ChordPro/Output/HTML5.pm` (config access simplification)
- `lib/ChordPro/Output/HTML5Paged.pm` (config access simplification)

**Validation**: All tests pass, no "Attempt to access disallowed key" errors

---

### Step 3: Investigate & Fix Songline First-Word Bug (Bug 2)

**Objective**: Fix positioning issue when songline doesn't start with a chord

**Investigation Steps**:

**3.1. Create minimal test case**

Create `testing/songline_bug.cho`:
```
{title: Songline Bug Test}

# Case 1: Normal line with leading chord
[C]First word with chord

# Case 2: Line without leading chord
Second word without leading chord

# Case 3: Chord mid-line
Third [D]word with mid chord
```

Generate HTML5 output:
```bash
perl -Ilib script/chordpro.pl --generate=HTML5 testing/songline_bug.cho -o /tmp/bug.html
```

**3.2. Inspect generated HTML structure**

Look for differences between:
- Pairs with chords
- Pairs with empty chords (`.cp-chord-empty`)
- First vs. subsequent pairs

**3.3. Examine CSS rendering**

Check these CSS rules in `html5/css/songlines.tt`:
- `.cp-chord-lyric-pair` alignment
- `.cp-chord` vs `.cp-chord-empty` height/padding
- `.cp-lyrics` vertical alignment
- Flexbox `align-items` behavior

**3.4. Root Cause Analysis**

Likely causes:
1. Empty chord span creates unexpected height → first lyrics span aligns to empty chord baseline
2. Flexbox `align-items: flex-start` positions first word differently
3. `.cp-chord-empty` class missing height/visibility CSS

**3.5. Implement Fix**

Probable solution (in `html5/css/songlines.tt`):
```css
.cp-chord-empty {
    visibility: hidden;
    height: 1em;  /* Ensure consistent height even when empty */
}
```

Or restructure HTML to only render chord span when chord exists:
```html
[% IF pair.chord %]
<span class="cp-chord">[% pair.chord | html %]</span>
[% END %]
```

**Testing**:
```bash
make
perl -Ilib script/chordpro.pl --generate=HTML5 testing/songline_bug.cho -o /tmp/bug.html
# Visually inspect in browser
```

**Files Modified**:
- Likely: `lib/ChordPro/res/templates/html5/css/songlines.tt`
- Possibly: `lib/ChordPro/res/templates/html5/songline.tt`
- Possibly: `lib/ChordPro/Output/HTML5.pm` (_render_songline_template method)

**Validation**: All songlines render with consistent baseline regardless of leading chord presence

---

### Step 4: Convert Class Methods to :common (Bug 3)

**Objective**: Use Object::Pad `:common` attribute for class methods

**Changes Required**:

**4.1. HTML5.pm - Update generate_songbook**

Line 795-809:
```perl
# Current:
sub generate_songbook {
    my $sb = shift;
    
    my $pkg = __PACKAGE__;
    my $backend = $pkg->new(
        songbook => $sb,
        config => $::config,
        options => $::options,
    );
    
    return $backend->generate_songbook();
}
```

Change to:
```perl
method generate_songbook :common ($sb) {
    # If called as class method, create instance
    unless (ref $self) {
        $self = $self->new(
            songbook => $sb,
            config => $::config,
            options => $::options,
        );
    }
    
    # Rest of implementation...
    return $self->_generate_songbook_impl();
}
```

**4.2. Ensure BUILD compatibility**

`:common` methods can be called as both class and instance methods. Verify BUILD block doesn't assume instance context.

**4.3. Update HTML5Paged.pm similarly** (if it has class method wrappers)

**Testing**:
```bash
make
make test
# Verify both class and instance calls work
```

**Files Modified**:
- `lib/ChordPro/Output/HTML5.pm` (generate_songbook method)
- `lib/ChordPro/Output/HTML5Paged.pm` (if applicable)

**Validation**: Backend can be invoked as both class and instance method

---

### Step 5: Add html.backend Config Option (Design Change 3)

**Objective**: Allow config-driven backend selection for .html files

**Changes Required**:

**5.1. Update chordpro_config.json**

Add new config option (around line 1162):
```json
"html": {
  "backend": "html",  // Options: "html" (legacy), "html5"
  "styles": {
    "display": "chordpro.css",
    "print": "chordpro_print.css"
  }
}
```

**5.2. Update ChordPro.pm backend selection**

Modify lines 125-155 (file extension detection):
```perl
if ( defined($of) && $of ne "" ) {
    if ( $of =~ /\.pdf$/i ) {
        $options->{generate} ||= "PDF";
    }
    elsif ( $of =~ /\.html?$/i ) {
        # Check html.backend config option
        my $html_backend = eval { $::config->{html}->{backend} } // 'html';
        if ( $html_backend eq 'html5' ) {
            $options->{generate} ||= "HTML5";
        } else {
            $options->{generate} ||= "HTML";  # Legacy
        }
    }
    # ... rest of extensions
}
```

**5.3. Alternative: html.module approach**

Instead of new config key, use existing pattern:
```json
"html": {
  "module": "HTML5"  // Override default HTML module
}
```

Then in ChordPro.pm:
```perl
elsif ( $of =~ /\.html?$/i ) {
    my $module = eval { $::config->{html}->{module} } // 'HTML';
    $options->{generate} ||= $module;
}
```

**Decision Point**: Choose one approach:
- **Option A**: `html.backend` - more explicit, clearer intent
- **Option B**: `html.module` - reuses existing pattern

**Recommendation**: Use `html.backend` for clarity.

**Testing**:
```bash
# Test default (legacy HTML)
perl -Ilib script/chordpro.pl t/basic.cho -o /tmp/test.html
# Should use legacy HTML backend

# Test with config override
echo '{ "html": { "backend": "html5" } }' > /tmp/test_config.json
perl -Ilib script/chordpro.pl --config=/tmp/test_config.json t/basic.cho -o /tmp/test.html
# Should use HTML5 backend
```

**Files Modified**:
- `lib/ChordPro.pm` (backend selection logic)
- `lib/ChordPro/res/config/chordpro_config.json` (add html.backend)

**Validation**: .html files use HTML5 backend when configured

---

### Step 6: Merge HTML5Paged into HTML5 (Design Change 2)

**Objective**: Consolidate paged functionality into main HTML5 backend with mode flag

**This is the LARGEST change** - requires careful planning.

**Architecture Decision**:

**Option A**: Single backend with config flag
```json
"html5": {
  "paged": {
    "enable": true  // Toggle paged mode
  }
}
```

**Option B**: Keep separate --generate options but share more code
- `--generate=HTML5` → screen-optimized
- `--generate=HTML5Paged` → print-optimized
- Both use same base class with conditional rendering

**Option C**: Responsive by default
- Always include both @media screen and @media print rules
- Let browser/print engine choose appropriate styles
- Simplest for users but larger CSS

**Recommendation**: **Option C** - Responsive by default
- Most user-friendly (works everywhere)
- Matches modern web development practices
- Eliminates need for backend selection

**Implementation Steps**:

**6.1. Audit feature differences**

HTML5Paged unique features:
- @page CSS rules (margins, size, headers/footers)
- Format parsing (`_generate_format_rules`)
- Metadata data attributes on song elements
- String-set CSS for page metadata
- Page-specific templates (songbook.tt, song.tt overrides)

**6.2. Move format generator to HTML5.pm**

Copy from HTML5Paged.pm lines 64-101:
- `_generate_format_rules()` method
- `_format_papersize()` helper
- `_format_margins()` helper

**6.3. Integrate paged CSS generation**

Merge `generate_paged_css()` logic into `generate_default_css()`:
```perl
method generate_default_css() {
    # Base CSS (screen)
    my $css = $self->_process_template('css', $vars);
    
    # Add paged CSS (print)
    my $paged_enabled = eval { $config->{html5}->{paged}->{enable} };
    if ($paged_enabled) {
        $css .= "\n" . $self->_generate_paged_css();
    }
    
    return $css;
}
```

**6.4. Update generate_song() for metadata attributes**

Add conditional metadata attributes when paged mode enabled:
```perl
method generate_song($song) {
    my $attrs = '';
    
    if ( eval { $config->{html5}->{paged}->{enable} } ) {
        # Add data-title, data-artist, etc.
        my $meta = $song->{meta};
        $attrs .= sprintf(' data-title="%s"', $self->escape_text($meta->{title}->[0]))
            if $meta->{title}->[0];
        # ... more attributes
    }
    
    return sprintf('<section class="song"%s>%s</section>', $attrs, $body);
}
```

**6.5. Consolidate templates**

Merge html5paged/ templates into html5/ with conditional sections:
- Keep base templates as-is
- Add paged-specific CSS in @media print blocks
- Remove html5paged/ directory after migration

**6.6. Update configuration schema**

Merge html5.paged config into html5 with enable flag:
```json
"html5": {
  "paged": {
    "enable": false,  // Default: screen-optimized
    "papersize": "a4",
    "margins": {
      "top": 80,
      "bottom": 40,
      // ...
    }
  }
}
```

**6.7. Deprecate HTML5Paged backend**

Two approaches:
1. **Hard deprecation**: Remove HTML5Paged.pm entirely
2. **Soft deprecation**: Make HTML5Paged.pm a thin wrapper that sets paged.enable=true

Recommendation: **Soft deprecation** for backward compatibility:
```perl
package ChordPro::Output::HTML5Paged;

use ChordPro::Output::HTML5;

sub generate_songbook {
    my $sb = shift;
    
    # Enable paged mode
    $::config->{html5}->{paged}->{enable} = 1;
    
    # Delegate to HTML5
    return ChordPro::Output::HTML5->generate_songbook($sb);
}

1;
```

**Testing**:
```bash
make
make test

# Test unpaged (default)
perl -Ilib script/chordpro.pl --generate=HTML5 t/basic.cho -o /tmp/unpaged.html

# Test paged (config-enabled)
perl -Ilib script/chordpro.pl --generate=HTML5 --config=<paged_config> t/basic.cho -o /tmp/paged.html

# Test backward compatibility
perl -Ilib script/chordpro.pl --generate=HTML5Paged t/basic.cho -o /tmp/legacy_paged.html
```

**Files Modified**:
- `lib/ChordPro/Output/HTML5.pm` (merge paged functionality)
- `lib/ChordPro/Output/HTML5Paged.pm` (convert to thin wrapper)
- `lib/ChordPro/res/config/chordpro_config.json` (merge config schemas)
- Templates: merge paged CSS into @media print blocks

**Files to Consider Removing** (after validation):
- `lib/ChordPro/res/templates/html5paged/` directory (if fully merged)

**Validation**:
- All existing HTML5 tests pass
- All existing HTML5Paged tests pass
- New responsive output works in browser and print preview

---

### Step 7: Update Tests

**Objective**: Ensure all changes are validated by test suite

**7.1. Update existing tests**

- `t/75_html5.t` - verify unpaged behavior unchanged
- `t/76_html5paged.t` - verify backward compatibility
- `t/html5paged/04_formats.t` - verify format parsing still works
- `t/html5paged/05_even_odd.t` - verify even/odd page rules
- `t/html5paged/06_e2e.t` - verify end-to-end workflow
- `t/html5paged/07_phase4_config.t` - verify config resolution

**7.2. Add new tests**

Create `testing/80_html5_responsive.t`:
- Test responsive CSS generation
- Test config-driven paged mode
- Test media query presence
- Test backward compatibility wrapper

**7.3. Update reference outputs**

After changes, regenerate reference files:
```bash
# For each test that compares output
perl -Ilib script/chordpro.pl <input> -o t/ref/<output>
```

**Testing**:
```bash
make test
make tests  # Include xt/ extended tests
```

**Files Modified**:
- Various test files in `t/` and `xt/`
- Reference files in `t/ref/`

**Validation**: Full test suite passes (108 tests currently passing)

---

### Step 8: Update Documentation

**Objective**: Document new features and migration guide

**8.1. Update copilot-instructions.md**

Add section about:
- Consolidated HTML5 backend architecture
- Responsive output approach
- Simplified config access patterns
- :common method usage

**8.2. Update user documentation**

Files to update:
- `docs/content/ChordPro-Configuration-HTML5.md` - new config options
- Main README - mention responsive HTML5 output
- Migration guide for HTML5Paged users

**8.3. Create ai-docs summary**

Document implementation decisions:
- Why responsive approach chosen
- Config access simplification rationale
- Template path resolution fix
- Backward compatibility strategy

**Files Modified**:
- `.github/copilot-instructions.md`
- `docs/content/ChordPro-Configuration-HTML5.md`
- `ai-docs/HTML5_CONSOLIDATION.md` (new)

---

## Implementation Order

**Phase 1: Quick Wins** (Steps 1-3)
1. Fix template path resolution (Bug 1) - immediate user impact
2. Simplify config access - code quality improvement
3. Fix songline bug (Bug 2) - visible rendering fix

**Phase 2: API Improvements** (Step 4)
4. Convert to :common methods - better API design

**Phase 3: Feature Work** (Steps 5-6)
5. Add html.backend config - user-facing feature
6. Merge HTML5Paged - major architectural change

**Phase 4: Validation** (Steps 7-8)
7. Update tests - ensure quality
8. Update documentation - knowledge transfer

---

## Risk Assessment

### High Risk
- **Step 6 (Merge HTML5Paged)**: Large refactoring, many integration points
  - Mitigation: Soft deprecation with wrapper maintains backward compatibility
  - Extensive testing before removing old code

### Medium Risk
- **Step 3 (Songline bug)**: Root cause unclear, fix might need iteration
  - Mitigation: Create comprehensive test case first, validate visually

### Low Risk
- Steps 1, 2, 4, 5: Isolated changes with clear scope

---

## Success Criteria

✓ All 108 existing tests pass  
✓ Template resolution works out of the box  
✓ Songline rendering correct without leading chords  
✓ html.backend config option functional  
✓ HTML5Paged wrapper maintains backward compatibility  
✓ Responsive HTML5 output works in browser and print  
✓ Code simplified (fewer eval{} wrappers)  
✓ Documentation updated

---

## Open Questions

1. **Responsive strategy**: Confirm Option C (responsive by default) is preferred
2. **Template reorganization**: Keep html5/ subdirectory or flatten structure?
3. **Config migration**: Auto-migrate old configs or require manual update?
4. **HTML5Paged fate**: Keep as wrapper indefinitely or document deprecation timeline?
5. **Default backend**: Should html.backend default to "html5" in future major version?

---

## Next Steps

1. Review this plan with maintainer
2. Get approval for architectural decisions (especially Step 6 approach)
3. Begin Phase 1 implementation
4. Iterate based on test results
5. Submit for code review after each phase

---

**End of Implementation Plan**
