# HTML5 Print Mode Feature Implementation - Executive Summary

## Overview

This document summarizes the feature completeness analysis of HTML5 print mode compared to PDF backend and provides the implementation roadmap.

**Date**: February 5, 2026  
**Status**: Analysis Complete, Ready for Implementation

## Key Findings

### Feature Completeness: ~70%

The HTML5 print mode has achieved substantial feature parity with PDF:

- ✅ **Complete (70%)**: Core features like page layout, styling, chord diagrams, special elements
- ⚠️ **Partial (15%)**: Headers/footers (basic), dual-page layout (CSS only)
- ❌ **Missing (15%)**: TOC, advanced headers/footers, songbook organization

### Critical Gaps (Must Fix)

1. **Table of Contents**: Completely missing - essential for multi-song books
2. **Enhanced Headers/Footers**: Missing format variants (first/title/even pages)
3. **Dual-Page Layout**: Lacking proper odd/even page styling for bound books

### Implementation Priority

```
HIGH PRIORITY (Must Have)
├── Table of Contents Generation [~8-12 hours]
├── Enhanced Headers/Footers [~4-6 hours]
└── Dual-Page Odd/Even Layout [~3-4 hours]

MEDIUM PRIORITY (Should Have)
├── Song Sorting [~2-3 hours]
├── Page Alignment (Right Pages) [~3-4 hours]
└── TOC Hierarchical Breaks [~2-3 hours]

LOW PRIORITY (Nice to Have)
├── Cover/Front/Back Matter [~3-4 hours]
├── Keyboard Diagrams [~6-8 hours]
└── Debug Output Mode [~2-3 hours]

DENIED (Not Applicable)
├── Song Compaction (too complex, low ROI)
├── PDF Bookmarks (PDF-specific)
├── Named Destinations (HTML has anchors)
└── CSV Export (separate backend)
```

**Total Estimated Effort**: 33-47 hours for full implementation

## Documents

### 1. Feature Analysis (`HTML5_PRINT_FEATURE_ANALYSIS.md`)

Comprehensive feature comparison matrix covering:
- Page layout and formatting
- Headers, footers, and page templates  
- Songbook features (sorting, alignment, covers)
- Table of contents (types, grouping, formatting)
- Chord diagrams (string and keyboard)
- Text styling and theming
- Images, media, and special elements

**Conclusion**: 70% feature complete, feasible to reach 95%+ with planned features.

### 2. Implementation Plan (`HTML5_PRINT_IMPLEMENTATION_PLAN.xml`)

Detailed task breakdown for each feature using required XML format:

```xml
<feature>
  <title>Feature Name</title>
  <implementation-decision>implement|denied</implementation-decision>
  <reason>Justification for decision</reason>
  <priority>High|Medium|Low</priority>
  <implementation-risks>
    <risk>Specific risk and mitigation</risk>
  </implementation-risks>
  <implementation-details>
    <task id="1">Step-by-step task with AI-friendly details</task>
    <task id="2">Next task</task>
  </implementation-details>
</feature>
```

**Features Covered**:
- ✅ 3 High Priority (implement)
- ✅ 3 Medium Priority (implement)  
- ✅ 3 Low Priority (implement)
- ✅ 4 Denied (with justification)

Each feature includes:
- Clear implementation decision with reasoning
- Risk assessment and mitigation strategies
- Detailed step-by-step tasks suitable for AI implementation
- Testing requirements and acceptance criteria

## Technical Approach

### Architecture Principles

1. **Reuse Existing Infrastructure**
   - Template::Toolkit for all rendering
   - Paged.js for pagination and print layout
   - Shared config with PDF backend (hybrid precedence)
   - ChordPro::Output::Common for TOC/outline code

2. **Incremental Implementation**
   - Start with high-priority features
   - Test thoroughly at each stage
   - Maintain backward compatibility
   - Document as we go

3. **Follow Established Patterns**
   - Object::Pad classes (not monolithic functions)
   - Template-based rendering (zero hardcoded HTML)
   - CSS variables for theming
   - Config-driven behavior (opt-in for new features)

### Key Technical Challenges

#### 1. Table of Contents with Page Numbers

**Challenge**: Page numbers only available after paged.js renders.

**Solution**: 
- Pre-generate TOC structure with placeholders
- Use paged.js "afterRendered" hook to populate page numbers
- Use data attributes for page references

```javascript
Paged.registerHandlers(class extends Handler {
  afterRendered(pages) {
    // Populate TOC page numbers from rendered pages
  }
});
```

#### 2. Even Page Mirroring

**Challenge**: Headers/footers must swap left/right parts on even pages.

**Solution**:
- CSS @page :left/:right selectors
- Automatic margin box mirroring in CSS generation
- Page numbers on outside edges (left on even, right on odd)

```css
@page :left {
  @bottom-left { content: counter(page); }
  @bottom-right { content: string(song-title); }
}
@page :right {
  @bottom-left { content: string(song-title); }
  @bottom-right { content: counter(page); }
}
```

#### 3. Song Sorting

**Challenge**: Must support locale-aware sorting.

**Solution**:
- Use Unicode::Collate (same as PDF)
- Sort before rendering
- Support multiple sort fields

```perl
my $collator = Unicode::Collate->new();
@songs = sort { 
  $collator->cmp($a->{meta}->{title}[0], $b->{meta}->{title}[0]) 
} @songs;
```

## Risk Assessment

### Technical Risks: LOW

- ✅ All technologies proven (paged.js, Template::Toolkit, CSS @page)
- ✅ Existing patterns to follow (Phase 4 implementation)
- ✅ No external dependencies needed
- ⚠️ Page number tracking requires JavaScript integration (manageable)

### Maintenance Risks: LOW

- ✅ Template system reduces code complexity
- ✅ Config-driven behavior (easy to adjust)
- ✅ Clear separation of concerns
- ⚠️ More templates to maintain (offset by better organization)

### Compatibility Risks: LOW

- ✅ Browser support good (Chrome/Chromium focus)
- ✅ Paged.js polyfills CSS @page features
- ✅ Backward compatible (all new features opt-in)
- ⚠️ Print-to-PDF quality varies by browser (document Chrome requirement)

### Project Risks: MEDIUM

- ⚠️ Large scope (33-47 hours estimated)
- ⚠️ Testing effort significant (each feature needs tests)
- ✅ Incremental approach mitigates risk
- ✅ Can defer low-priority features

## Success Metrics

### Must Achieve (High Priority)

- [ ] Table of Contents generated with accurate page numbers
- [ ] Headers/footers support first, title, and even page formats
- [ ] Odd/even pages styled differently for binding
- [ ] All features tested with 50+ song songbook
- [ ] Documentation complete for all new features

### Should Achieve (Medium Priority)

- [ ] Songs sortable by title or artist
- [ ] Songs can start on right pages for binding
- [ ] TOC supports hierarchical breaks (A, B, C sections)

### Nice to Have (Low Priority)

- [ ] Cover and matter pages supported
- [ ] Keyboard diagrams rendered
- [ ] Debug mode available

## Testing Strategy

### Unit Tests
- Test each feature in isolation
- Mock paged.js rendering where needed
- Verify config parsing and CSS generation

### Integration Tests
- Test features combined in realistic songbooks
- Small songbook (3-5 songs) for quick iteration
- Large songbook (50+ songs) for performance
- Edge cases (empty TOC, single song, no headers)

### Visual Regression Tests
- Generate HTML output for each test case
- Open in Chrome print preview
- Compare against reference screenshots
- Document expected vs actual for failing tests

### Browser Compatibility Tests
- Primary: Chrome/Chromium (best CSS @page support)
- Secondary: Firefox, Safari (document limitations)
- Test print-to-PDF output quality

## Next Steps

### Phase 1: Foundation (Week 1)
1. Implement Table of Contents basic structure
2. Add paged.js page number integration
3. Test with simple songbook (5 songs)

### Phase 2: Enhancement (Week 2)
1. Implement enhanced headers/footers
2. Add odd/even page styling
3. Test with bound songbook scenario

### Phase 3: Organization (Week 3)
1. Implement song sorting
2. Add page alignment features
3. Add TOC hierarchical breaks

### Phase 4: Polish (Week 4)
1. Implement low-priority features (as time permits)
2. Comprehensive testing and bug fixes
3. Documentation and examples

## Conclusion

The HTML5 print mode feature analysis is complete. The implementation plan is detailed, feasible, and follows established ChordPro patterns. With incremental implementation and thorough testing, we can achieve 95%+ feature parity with PDF while maintaining the advantages of HTML (styling flexibility, web integration, accessibility).

**Recommendation**: Proceed with implementation, starting with high-priority features.

---

**Prepared by**: GitHub Copilot Agent  
**Reviewed by**: Pending  
**Approved by**: Pending

## Appendix: File Locations

- **Analysis**: `/home/runner/work/chordpro/chordpro/ai-docs/HTML5_PRINT_FEATURE_ANALYSIS.md`
- **Implementation Plan**: `/home/runner/work/chordpro/chordpro/ai-docs/HTML5_PRINT_IMPLEMENTATION_PLAN.xml`
- **Summary**: `/home/runner/work/chordpro/chordpro/ai-docs/HTML5_PRINT_EXECUTIVE_SUMMARY.md` (this document)
