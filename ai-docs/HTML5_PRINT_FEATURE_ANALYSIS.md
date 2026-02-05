# HTML5 Print Mode Feature Completeness Analysis

## Executive Summary

This document analyzes the HTML5 print mode feature completeness compared to the PDF backend and provides an implementation plan for missing features.

**Analysis Date**: February 5, 2026  
**ChordPro Version**: Development (main branch)

## Feature Comparison Matrix

| Feature Category | PDF Backend | HTML5 Print | Status | Priority |
|-----------------|-------------|-------------|--------|----------|
| **Page Layout** |
| Custom page sizes | ✅ Full | ✅ Full | Complete | - |
| Margins (top/bottom/left/right) | ✅ Full | ✅ Full | Complete | - |
| Multi-column layout | ✅ Full | ✅ Full | Complete | - |
| Dual-page (odd/even) support | ✅ Full | ⚠️ Partial | Incomplete | High |
| Page alignment (songs to right pages) | ✅ Full | ❌ Missing | Gap | Medium |
| **Headers & Footers** |
| Basic headers/footers | ✅ Full | ✅ Full | Complete | - |
| Three-part formatting (L/C/R) | ✅ Full | ⚠️ Partial | Incomplete | High |
| Even page mirroring | ✅ Full | ❌ Missing | Gap | High |
| Format templates (first/title/default) | ✅ Full | ⚠️ Partial | Incomplete | High |
| Metadata substitution | ✅ Full | ✅ Full | Complete | - |
| **Songbook Features** |
| Song sorting | ✅ Full | ❌ Missing | Gap | Medium |
| Song compaction (minimal page turns) | ✅ Full | ❌ Missing | Gap | Low |
| Cover pages | ✅ Full | ❌ Missing | Gap | Low |
| Front/back matter | ✅ Full | ❌ Missing | Gap | Low |
| **Table of Contents** |
| Multiple TOCs | ✅ Full | ❌ Missing | Gap | High |
| Flexible grouping | ✅ Full | ❌ Missing | Gap | High |
| Hierarchical breaks | ✅ Full | ❌ Missing | Gap | Medium |
| Custom formatting | ✅ Full | ❌ Missing | Gap | Medium |
| Page number references | ✅ Full | ❌ Missing | Gap | High |
| **Bookmarks & Navigation** |
| PDF bookmarks/outlines | ✅ Full | ❌ N/A | N/A | - |
| Named destinations | ✅ Full | ❌ N/A | N/A | - |
| Page labels | ✅ Full | ❌ N/A | N/A | - |
| **Chord Diagrams** |
| String instrument diagrams | ✅ Full | ✅ Full | Complete | - |
| Keyboard/piano diagrams | ✅ Full | ⚠️ Partial | Incomplete | Low |
| Position control | ✅ Full | ✅ Full | Complete | - |
| Suppression list | ✅ Full | ✅ Full | Complete | - |
| **Text Styling** |
| Multiple font families | ✅ Full | ✅ Full | Complete | - |
| Font sizes per element | ✅ Full | ✅ Full | Complete | - |
| Colors (256+) | ✅ Full | ✅ Full | Complete | - |
| Theme colors | ✅ Full | ✅ Full | Complete | - |
| **Images & Media** |
| Inline images | ✅ Full | ✅ Full | Complete | - |
| SVG embedding | ✅ Full | ✅ Full | Complete | - |
| ABC notation | ✅ Full | ✅ Full | Complete | - |
| Lilypond notation | ✅ Full | ✅ Full | Complete | - |
| **Special Elements** |
| Comments (plain/italic/boxed) | ✅ Full | ✅ Full | Complete | - |
| Tabs (tablature) | ✅ Full | ✅ Full | Complete | - |
| Grids (chord patterns) | ✅ Full | ✅ Full | Complete | - |
| **Export Features** |
| CSV export (MobileSheets) | ✅ Full | ❌ N/A | N/A | - |
| **Configuration** |
| Song-level overrides | ✅ Full | ✅ Full | Complete | - |
| Debug output | ✅ Full | ⚠️ Partial | Incomplete | Low |

## Legend

- ✅ **Full**: Feature fully implemented and tested
- ⚠️ **Partial**: Feature partially implemented or needs enhancement
- ❌ **Missing**: Feature not implemented
- **N/A**: Feature not applicable to HTML5 output

## Critical Gaps Analysis

### High Priority Gaps

1. **Table of Contents (TOC) Generation**
   - **Status**: Completely missing
   - **Impact**: Essential for songbooks with many songs
   - **PDF Features**: Multiple TOCs, grouping, hierarchical breaks, page references
   - **Complexity**: High - requires page number tracking with paged.js

2. **Enhanced Headers/Footers**
   - **Status**: Partial implementation
   - **Missing**: Even page mirroring, format template variants (first/title/default)
   - **Impact**: Professional print output for bound songbooks
   - **Complexity**: Medium - extends existing CSS @page implementation

3. **Dual-Page Layout (Odd/Even)**
   - **Status**: Partial CSS support
   - **Missing**: Full odd/even page styling, automatic margin swapping
   - **Impact**: Essential for bound songbooks with facing pages
   - **Complexity**: Medium - CSS @page :left/:right selectors

### Medium Priority Gaps

4. **Song Sorting**
   - **Status**: Missing
   - **Impact**: User convenience for organizing songbooks
   - **Complexity**: Low - sort before rendering

5. **Page Alignment (Songs to Right Pages)**
   - **Status**: Missing
   - **Impact**: Professional binding with songs always on right-facing pages
   - **Complexity**: Medium - requires page tracking and filler pages

6. **TOC Hierarchical Breaks**
   - **Status**: Missing
   - **Impact**: Better organization for large songbooks
   - **Complexity**: Medium - extends TOC implementation

### Low Priority Gaps

7. **Song Compaction**
   - **Status**: Missing
   - **Impact**: Optimizes page usage (nice-to-have)
   - **Complexity**: High - requires layout simulation

8. **Cover/Front/Back Matter**
   - **Status**: Missing
   - **Impact**: Professional presentation (workaround: external tools)
   - **Complexity**: Low - static page insertion

9. **Keyboard Diagrams**
   - **Status**: Placeholder only
   - **Impact**: Limited use case (mostly string instruments)
   - **Complexity**: Medium - SVG rendering logic

10. **Debug Output**
    - **Status**: Partial
    - **Impact**: Development convenience
    - **Complexity**: Low - add debug classes/comments

## Features Denied for HTML5

### PDF-Specific Features

1. **PDF Bookmarks/Outlines**
   - **Reason**: HTML has no equivalent to PDF bookmarks
   - **Alternative**: HTML anchor links in TOC

2. **Named Destinations**
   - **Reason**: PDF-specific feature
   - **Alternative**: HTML `id` attributes and fragment links

3. **CSV Export**
   - **Reason**: Not an output format feature
   - **Alternative**: Separate export backend if needed

4. **Page Labels (custom numbering)**
   - **Reason**: Limited CSS support for custom page number schemes
   - **Alternative**: CSS counters provide basic page numbering

## Implementation Risks & Mitigation

### Technical Risks

1. **Paged.js Limitations**
   - **Risk**: Paged.js may not support all desired features
   - **Mitigation**: Test features incrementally, have fallback approaches
   - **Status**: Well-documented library with active community

2. **Page Number Tracking**
   - **Risk**: Page numbers not available until paged.js renders
   - **Mitigation**: Use paged.js hooks for dynamic content
   - **Complexity**: Requires JavaScript integration

3. **Browser Compatibility**
   - **Risk**: CSS @page features vary by browser/PDF engine
   - **Mitigation**: Test with Chrome/Chromium (best support), document requirements
   - **Status**: Paged.js polyfills many features

4. **Performance with Large Songbooks**
   - **Risk**: TOC generation and sorting may slow rendering
   - **Mitigation**: Optimize algorithms, consider pagination
   - **Status**: Modern browsers handle large DOMs well

### Maintenance Risks

1. **Template Complexity**
   - **Risk**: More templates increase maintenance burden
   - **Mitigation**: Follow established patterns, document well
   - **Status**: Template system already in place

2. **Config Compatibility**
   - **Risk**: PDF and HTML5 configs may diverge
   - **Mitigation**: Share configs where possible, document differences
   - **Status**: Hybrid config system already works well

## Dependencies & Prerequisites

### External Dependencies
- **Paged.js**: Already integrated (v0.4.3)
- **Template::Toolkit**: Already integrated
- **Modern Browser**: Chrome/Chromium recommended for PDF generation

### Internal Dependencies
- **ChordPro::Output::Common**: Shared TOC/outline code
- **HTML5 template system**: Established pattern to follow
- **Config system**: JSON-based configuration

### Testing Requirements
- Unit tests for new features
- Integration tests with sample songbooks
- Visual regression tests for print output
- Browser compatibility testing

## Backward Compatibility

All new features will:
1. Be disabled by default (opt-in via config)
2. Not affect existing HTML5 output without config changes
3. Maintain API compatibility with existing code
4. Support both legacy and new config formats

## Success Criteria

### Must Have (High Priority)
- ✅ Table of Contents with page numbers
- ✅ Enhanced headers/footers with format templates
- ✅ Odd/even page support

### Should Have (Medium Priority)
- ✅ Song sorting
- ✅ Page alignment for binding

### Nice to Have (Low Priority)
- ✅ Song compaction
- ✅ Cover pages
- ✅ Keyboard diagrams

## Conclusion

The HTML5 print mode is **~70% feature-complete** compared to PDF. The main gaps are in:
1. **Table of Contents** (missing entirely)
2. **Enhanced page layout** (partial implementation)
3. **Songbook organization** (sorting, alignment)

These features are **feasible to implement** using paged.js and existing ChordPro infrastructure. The implementation should be **incremental** with thorough testing at each stage.

---

**Next Steps**: See detailed implementation plan in HTML5_PRINT_IMPLEMENTATION_PLAN.xml
