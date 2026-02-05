# HTML5 Backend Consolidation Plan

**Status**: Ready for Implementation  
**Estimated Effort**: 4-6 hours  
**Risk Level**: Medium (large refactoring, but well-scoped)  
**Test Coverage**: 108 tests currently passing - must maintain

## Executive Summary

Merge HTML5Paged.pm (522 lines) into HTML5.pm (1006 lines) to create a single responsive backend that works for both screen and print output. HTML5Paged will become a thin wrapper for backward compatibility.

**Primary Goal**: Eliminate code duplication while maintaining backward compatibility.

**Strategy**: Use responsive CSS with `@media screen` and `@media print` rules, letting the browser/print engine choose the appropriate styling.

## Current Architecture Assessment

### File Inventory

**Backend Code**:
- `lib/ChordPro/Output/HTML5.pm` - 1006 lines (base backend)
- `lib/ChordPro/Output/HTML5Paged.pm` - 522 lines (paged extension)
- `lib/ChordPro/Output/HTML5Paged/FormatGenerator.pm` - format parsing

**Templates** (HTML5):
- Structural: 6 files (songbook.tt, song.tt, songline.tt, comment.tt, image.tt, chord-diagrams.tt)
- CSS: 9 files (base.tt, typography.tt, songlines.tt, sections.tt, tab-grid.tt, chord-diagrams.tt, print-media.tt, body-page.tt, variables.tt)

**Templates** (HTML5Paged - overrides):
- Structural: 2 files (songbook.tt, song.tt)
- CSS: 7 files (base.tt, string-set.tt, page-setup.tt, variables.tt, typography.tt, layout.tt, print-media.tt)

### HTML5Paged Unique Features

**Methods** (13 total):
1. `render_document_begin()` - adds paged.js script tag
2. `render_document_end()` - wraps content differently
3. `generate_song()` - adds data-* attributes for metadata
4. `generate_paged_css()` - generates @page rules
5. `_resolve_theme_colors()` - PDF config → CSS (Phase 4)
6. `_resolve_spacing()` - spacing multipliers
7. `_resolve_chorus_styles()` - chorus bar styling
8. `_resolve_grid_styles()` - grid colors
9. `_convert_color_to_css()` - color format converter
10. `_format_papersize()` - converts paper size to CSS
11. `_format_margins()` - converts margins (pt → mm)
12. `_pt_to_mm()`, `_mm_to_pt()` - unit conversion helpers

**Key Dependencies**:
- `ChordPro::Output::HTML5Paged::FormatGenerator` - parses PDF format specs into CSS @page rules
- paged.js library (loaded via CDN)
- PDF config fallbacks for theme, spacing, chorus, grid

### Implementation Readiness: ✅ READY

**Green Flags**:
- ✅ Both backends use Template::Toolkit (easy to merge templates)
- ✅ HTML5Paged extends HTML5 via Object::Pad inheritance
- ✅ Clear separation of concerns (paged features well-encapsulated)
- ✅ All 108 tests passing (good baseline)
- ✅ Extensive template system makes conditional rendering straightforward
- ✅ Phase 4 already established PDF config compatibility patterns

**Yellow Flags**:
- ⚠️ Separate template engines in HTML5Paged BUILD block (can merge)
- ⚠️ Regex-based metadata attribute injection (better to template it)
- ⚠️ Template paths hardcoded in both backends (need config-driven)

**No Red Flags**: Well-architected code, clean separation, good test coverage.

## Recommended Approach: Option C - Responsive by Default

### Why Responsive?

**User Benefits**:
- Single command produces output that works everywhere
- No need to choose backend or mode
- Natural print behavior (browser uses print styles automatically)
- Matches modern web development best practices

**Implementation Benefits**:
- Simpler config (no paged.enable toggle needed)
- Smaller codebase (no conditional logic in methods)
- Easier maintenance (one code path)
- Better tested (all features always active)

**Tradeoffs**:
- Slightly larger CSS (~30% increase) - acceptable for 2026
- Print-specific CSS loaded even for screen viewing - negligible performance impact

### Architecture: Mode-Based Rendering (Compromise)

While responsive is recommended, implement with mode flag for flexibility:

```json
"html5": {
  "mode": "responsive",  // Options: "screen", "print", "responsive"
  "paged": {
    "papersize": "a4",
    "margins": { ... },
    "formats": { ... }
  }
}
```

**Modes**:
- `"responsive"` (default): Includes both screen and print CSS
- `"screen"`: Screen-only CSS (smaller file size)
- `"print"`: Print-only CSS with @page rules

This gives power users control while defaulting to responsive (best UX).

## Implementation Plan

### Phase 1: Preparation (30 min)

**1.1. Create backup branch**
```bash
git checkout -b html5-consolidation-backup
git checkout html5
```

**1.2. Verify test baseline**
```bash
make test
# All 108 tests must pass
```

**1.3. Document current output**
```bash
perl -Ilib script/chordpro.pl --generate=HTML5 t/basic01.cho -o /tmp/before_html5.html
perl -Ilib script/chordpro.pl --generate=HTML5Paged t/basic01.cho -o /tmp/before_paged.html
```

### Phase 2: Move Paged Features to HTML5.pm (2 hours)

**2.1. Copy paged methods to HTML5.pm**

Add before the closing brace (after line ~1000):

```perl
# =================================================================
# PAGED OUTPUT SUPPORT (merged from HTML5Paged)
# =================================================================

method generate_paged_css() {
    # Copy from HTML5Paged.pm lines 250-345
    # Handles @page rules, PDF config fallbacks, format generation
}

method _resolve_theme_colors() {
    # Copy from HTML5Paged.pm lines 156-174
}

method _resolve_spacing() {
    # Copy from HTML5Paged.pm lines 176-193
}

method _resolve_chorus_styles() {
    # Copy from HTML5Paged.pm lines 195-217
}

method _resolve_grid_styles() {
    # Copy from HTML5Paged.pm lines 219-238
}

method _convert_color_to_css($color) {
    # Copy from HTML5Paged.pm lines 240-248
}

method _format_papersize($papersize) {
    # Copy from HTML5Paged.pm lines 351-378
}

method _format_margins($top, $right, $bottom, $left) {
    # Copy from HTML5Paged.pm lines 380-391
}

method _pt_to_mm($pt) { return $pt * 0.352777778; }
method _mm_to_pt($mm) { return $mm * 2.83464567; }
```

**2.2. Add FormatGenerator field to HTML5.pm**

Add after line ~26:
```perl
field $svg_generator;
field $template_engine;
field $format_generator;  # For PDF format → CSS translation
```

Update BUILD block (after line ~56):
```perl
# Initialize FormatGenerator for paged output
use ChordPro::Output::HTML5Paged::FormatGenerator;
$format_generator = ChordPro::Output::HTML5Paged::FormatGenerator->new(
    config => $self->config,
    options => $self->options,
);
```

**2.3. Integrate paged CSS into main CSS generation**

Modify `generate_default_css()` (around line ~650):
```perl
method generate_default_css() {
    # Base CSS (screen optimized)
    my $css = $self->_process_template('css', $vars);
    
    # Check mode configuration
    my $config = $self->config;
    my $mode = eval { $config->{html5}->{mode} } // 'responsive';
    
    if ($mode eq 'print' || $mode eq 'responsive') {
        # Add paged CSS (within @media print)
        $css .= "\n\n" . $self->generate_paged_css();
    }
    
    return $css;
}
```

**2.4. Add metadata attributes to generate_song()**

Modify `generate_song()` method (around line ~760):
```perl
method generate_song($song) {
    # Existing structurization
    $song->structurize() if $song->can('structurize');
    
    my $config = $self->config;
    my $mode = eval { $config->{html5}->{mode} } // 'responsive';
    my $add_metadata_attrs = ($mode eq 'print' || $mode eq 'responsive');
    
    # ... existing code ...
    
    # Add data-* attributes if paged mode enabled
    if ($add_metadata_attrs) {
        $output = $self->_add_metadata_attributes($output, $song);
    }
    
    return $output;
}

method _add_metadata_attributes($html, $song) {
    # Add data-title, data-artist, etc. for CSS string-set
    # Copy logic from HTML5Paged.pm lines 99-151
    # Better: use Template::Toolkit to inject during generation
}
```

**Files Modified**:
- `lib/ChordPro/Output/HTML5.pm` (+250 lines estimated)

### Phase 3: Convert HTML5Paged to Wrapper (30 min)

**3.1. Replace HTML5Paged.pm with thin wrapper**

```perl
#! perl

package main;

our $config;
our $options;

package ChordPro::Output::HTML5Paged;

# Backward compatibility wrapper for HTML5 backend
# Sets mode to 'print' and delegates to HTML5

use v5.26;
use ChordPro::Output::HTML5;

our $VERSION = '1.0';

sub generate_songbook {
    my ($class, $sb) = @_;
    
    # Enable print mode for backward compatibility
    $::config->{html5}->{mode} = 'print';
    $::config->{html5}->{paged}->{enable} = 1;  # Deprecated flag for old configs
    
    # Delegate to HTML5 backend
    return ChordPro::Output::HTML5->generate_songbook($sb);
}

1;

__END__

=head1 NAME

ChordPro::Output::HTML5Paged - Backward compatibility wrapper

=head1 DESCRIPTION

This module provides backward compatibility for the HTML5Paged backend.
It delegates to the HTML5 backend with print mode enabled.

New code should use:
    --generate=HTML5 --config=print_config.json

Instead of:
    --generate=HTML5Paged

=head1 DEPRECATION

This module will be removed in a future major version.
Please migrate to the HTML5 backend with mode configuration.

=cut
```

**Files Modified**:
- `lib/ChordPro/Output/HTML5Paged.pm` (reduces from 522 to ~50 lines)

**Files Deletable Later** (after migration period):
- `lib/ChordPro/Output/HTML5Paged.pm` (can remove in v7.x)

### Phase 4: Merge Templates (1 hour)

**4.1. Consolidate CSS templates**

Create `lib/ChordPro/res/templates/html5/css/paged.tt`:
```css
/* Paged output support (@media print) */
/* Merged from html5paged/css/ templates */

@media print {
  [% INCLUDE 'html5paged/css/page-setup.tt' %]
  [% INCLUDE 'html5paged/css/string-set.tt' %]
  [% INCLUDE 'html5paged/css/typography.tt' %]
  [% INCLUDE 'html5paged/css/layout.tt' %]
  [% INCLUDE 'html5paged/css/print-media.tt' %]
}
```

Update `lib/ChordPro/res/templates/html5/css/base.tt`:
```css
[% INCLUDE 'html5/css/variables.tt' %]
[% INCLUDE 'html5/css/typography.tt' %]
[% INCLUDE 'html5/css/songlines.tt' %]
[% INCLUDE 'html5/css/sections.tt' %]
[% INCLUDE 'html5/css/tab-grid.tt' %]
[% INCLUDE 'html5/css/chord-diagrams.tt' %]
[% INCLUDE 'html5/css/body-page.tt' %]
[% INCLUDE 'html5/css/print-media.tt' %]

/* Paged output (if mode = print or responsive) */
[% IF mode == 'print' || mode == 'responsive' %]
  [% INCLUDE 'html5/css/paged.tt' %]
[% END %]
```

**4.2. Keep html5paged/ templates for reference**

Don't delete yet - useful for diffing and verification.

**Files Modified**:
- `lib/ChordPro/res/templates/html5/css/base.tt`
- `lib/ChordPro/res/templates/html5/css/paged.tt` (new)

**Files to Keep** (for now):
- All `lib/ChordPro/res/templates/html5paged/*.tt` (mark deprecated)

### Phase 5: Update Configuration (30 min)

**5.1. Update chordpro.json**

Modify `lib/ChordPro/res/config/chordpro.json` (around line 1170):

```json
"html5": {
  // Output mode: "responsive" (default), "screen", "print"
  // responsive: Includes both screen and print CSS
  // screen: Screen-optimized only (smaller files)
  // print: Print-optimized with @page rules
  "mode": "responsive",
  
  "template_include_path": [],
  
  "templates": {
    "css": "html5/css/base.tt",
    "songbook": "html5/songbook.tt",
    "song": "html5/song.tt",
    "comment": "html5/comment.tt",
    "image": "html5/image.tt",
    "songline": "html5/songline.tt",
    "chord_diagrams": "html5/chord-diagrams.tt"
  },
  
  "css": {
    "colors": {},
    "fonts": {},
    "sizes": {},
    "spacing": {}
  },
  
  // Paged output configuration (used when mode = "print" or "responsive")
  "paged": {
    // Deprecated: use "mode" instead
    // "enable": false,
    
    "papersize": "a4",
    "margintop": 80,
    "marginbottom": 40,
    "marginleft": 40,
    "marginright": 40,
    "headspace": 60,
    "footspace": 20,
    
    "template_include_path": [],
    "templates": {
      "css": "html5paged/css/base.tt"
    },
    "css": {
      "colors": {},
      "fonts": {},
      "sizes": {}
    }
  }
}
```

**5.2. Regenerate Config::Data.pm**

```bash
perl script/cfgboot.pl lib/ChordPro/res/config/chordpro.json --output=lib/ChordPro/Config/Data.pm
```

**Files Modified**:
- `lib/ChordPro/res/config/chordpro.json`
- `lib/ChordPro/Config/Data.pm` (regenerated)

### Phase 6: Testing & Validation (1 hour)

**6.1. Build & Test**

```bash
make clean
perl Makefile.PL
make
make test
```

**Expected**: All 108 tests pass

**6.2. Manual Testing**

```bash
# Test responsive mode (default)
perl -Ilib script/chordpro.pl --generate=HTML5 t/basic01.cho -o /tmp/responsive.html
# Check: includes both screen and print CSS

# Test screen mode
echo '{"html5": {"mode": "screen"}}' > /tmp/screen_config.json
perl -Ilib script/chordpro.pl --generate=HTML5 --config=/tmp/screen_config.json t/basic01.cho -o /tmp/screen.html
# Check: no @page rules

# Test print mode
echo '{"html5": {"mode": "print"}}' > /tmp/print_config.json
perl -Ilib script/chordpro.pl --generate=HTML5 --config=/tmp/print_config.json t/basic01.cho -o /tmp/print.html
# Check: includes @page rules

# Test backward compatibility
perl -Ilib script/chordpro.pl --generate=HTML5Paged t/basic01.cho -o /tmp/legacy.html
# Check: identical to print mode
```

**6.3. Visual Verification**

Open outputs in browser:
- `/tmp/responsive.html` - check screen and print preview
- `/tmp/screen.html` - check looks good on screen
- `/tmp/print.html` - check print preview works
- `/tmp/legacy.html` - compare with original HTML5Paged output

**6.4. Diff Verification**

```bash
# Compare old vs new paged output
diff /tmp/before_paged.html /tmp/legacy.html
# Should be minimal differences (just wrapper changes)
```

### Phase 7: Documentation Updates (30 min)

**7.1. Update copilot-instructions.md**

Add section documenting:
- Consolidated HTML5 backend architecture
- Mode configuration options
- HTML5Paged deprecation status
- Migration guide for old configs

**7.2. Create migration guide**

Document in `ai-docs/HTML5_MIGRATION_GUIDE.md`:
- How to migrate from HTML5Paged
- Mode configuration examples
- Template customization patterns
- Troubleshooting common issues

**7.3. Update user docs**

Update `docs/content/ChordPro-Configuration-HTML5.md`:
- New mode option
- Paged configuration section
- Examples for different use cases

## Risk Mitigation

### Rollback Plan

If tests fail or regressions found:
```bash
# Restore from backup
git checkout html5-consolidation-backup

# Or revert specific commits
git revert HEAD~3..HEAD  # Revert last 3 commits
```

### Incremental Approach

Can split into smaller steps if needed:
1. **Phase 2 only**: Move methods, keep both backends functional
2. **Test extensively**
3. **Phase 3-4**: Convert to wrapper + merge templates
4. **Test again**
5. **Phase 5-7**: Config + docs

### Compatibility Testing

Before declaring complete:
- ✅ All 108 existing tests pass
- ✅ HTML5 output unchanged for screen use
- ✅ HTML5Paged wrapper produces equivalent output
- ✅ Responsive mode works in browser + print
- ✅ No deprecated warnings for valid configs

## Success Criteria

**Functional**:
- [ ] All 108 tests pass
- [ ] HTML5 backend supports responsive/screen/print modes
- [ ] HTML5Paged wrapper maintains backward compatibility
- [ ] Print output quality unchanged from HTML5Paged
- [ ] Screen output quality maintained from HTML5

**Code Quality**:
- [ ] ~250 lines added to HTML5.pm (not 522)
- [ ] HTML5Paged.pm reduced to ~50 lines
- [ ] No duplicate code between backends
- [ ] Template organization clear and maintainable

**Documentation**:
- [ ] Migration guide created
- [ ] User docs updated
- [ ] copilot-instructions.md updated
- [ ] Code comments explain mode behavior

## Post-Implementation Cleanup

**After 1-2 Release Cycles**:

1. Add deprecation warning to HTML5Paged wrapper
2. Update all examples to use HTML5 + mode config
3. Consider removing HTML5Paged in next major version

**After Removal** (v7.x):
- Delete `lib/ChordPro/Output/HTML5Paged.pm`
- Delete `lib/ChordPro/res/templates/html5paged/` directory
- Update config schema to remove html5.paged.enable

## Quick Reference

### Key Files

**Code**:
- `lib/ChordPro/Output/HTML5.pm` - main backend (add paged methods)
- `lib/ChordPro/Output/HTML5Paged.pm` - backward compat wrapper
- `lib/ChordPro/Output/HTML5Paged/FormatGenerator.pm` - keep as-is

**Config**:
- `lib/ChordPro/res/config/chordpro.json` - add mode option
- `lib/ChordPro/Config/Data.pm` - regenerate after config changes

**Templates**:
- `lib/ChordPro/res/templates/html5/css/base.tt` - add mode conditional
- `lib/ChordPro/res/templates/html5/css/paged.tt` - new paged CSS

### Test Commands

```bash
# Full build
make clean && perl Makefile.PL && make && make test

# Quick verification
perl -Ilib script/chordpro.pl --generate=HTML5 t/basic01.cho -o /tmp/test.html
perl -Ilib script/chordpro.pl --generate=HTML5Paged t/basic01.cho -o /tmp/test_paged.html

# Compare outputs
diff /tmp/test.html /tmp/test_paged.html
```

### Estimated Timeline

- **Phase 1**: 30 min (preparation)
- **Phase 2**: 2 hours (move methods)
- **Phase 3**: 30 min (wrapper conversion)
- **Phase 4**: 1 hour (merge templates)
- **Phase 5**: 30 min (update config)
- **Phase 6**: 1 hour (testing)
- **Phase 7**: 30 min (documentation)

**Total**: 6 hours (plus buffer for unexpected issues)

### Contact Points

- Original plan: `ai-docs/changes-bugs.md` (Step 6)
- Step 5 summary: `ai-docs/STEP5_IMPLEMENTATION_SUMMARY.md`
- Test baseline: All 108 tests passing
- Backup: `html5-consolidation-backup` branch

---

**Status**: Ready for implementation. Well-scoped plan with clear phases, rollback strategy, and success criteria.
