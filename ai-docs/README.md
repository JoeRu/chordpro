# Quick Reference: HTML5 Print Feature Implementation

## Document Navigation

1. **Executive Summary** (`HTML5_PRINT_EXECUTIVE_SUMMARY.md`)
   - Start here for overview
   - Key findings and priorities
   - Timeline and effort estimates

2. **Feature Analysis** (`HTML5_PRINT_FEATURE_ANALYSIS.md`)
   - Detailed feature comparison matrix
   - Gap analysis by category
   - Risk assessment

3. **Implementation Plan** (`HTML5_PRINT_IMPLEMENTATION_PLAN.xml`)
   - Detailed task breakdowns
   - Risk mitigation strategies
   - AI-ready implementation steps

## Feature Summary

### ✅ Implement (9 features)

#### High Priority
1. **Table of Contents** - Essential for multi-song books, ~8-12 hours
2. **Enhanced Headers/Footers** - Format variants, ~4-6 hours
3. **Dual-Page Layout** - Odd/even styling, ~3-4 hours

#### Medium Priority
4. **Song Sorting** - User convenience, ~2-3 hours
5. **Page Alignment** - Songs to right pages, ~3-4 hours
6. **TOC Hierarchical Breaks** - Better organization, ~2-3 hours

#### Low Priority
7. **Cover/Front/Back Matter** - Professional polish, ~3-4 hours
8. **Keyboard Diagrams** - Piano chord rendering, ~6-8 hours
9. **Debug Output** - Development tool, ~2-3 hours

### ❌ Denied (4 features)

1. **Song Compaction** - Too complex, low ROI
2. **PDF Bookmarks** - PDF-specific feature
3. **Named Destinations** - HTML has anchors already
4. **CSV Export** - Separate backend concern

## Implementation Pattern Example

Here's how each feature is documented in the XML plan:

```xml
<feature>
  <title>Table of Contents (TOC) Generation</title>
  <implementation-decision>implement</implementation-decision>
  <reason>
    Essential feature for multi-song songbooks. PDF has sophisticated TOC support
    with multiple TOCs, grouping, and page references. HTML5 print lacks this entirely.
    Users need this for professional songbook production. The feature is feasible using
    paged.js hooks for page number tracking and Template::Toolkit for rendering.
  </reason>
  <priority>High</priority>
  <implementation-risks>
    <risk>
      Paged.js async rendering: Page numbers only available after paged.js completes layout.
      Mitigation: Use paged.js "afterRendered" hook to populate TOC page numbers dynamically.
    </risk>
    <!-- More risks... -->
  </implementation-risks>
  <implementation-details>
    <task id="1">
      Study existing TOC implementation in lib/ChordPro/Output/PDF.pm (search for "toc", "contents").
      Understand how PDF backend uses ChordPro::Output::Common::prep_outlines() for TOC data.
    </task>
    <task id="2">
      Add TOC support to HTML5.pm backend:
      - Add _generate_toc() method to create TOC structure from songbook
      - Extract metadata (title, artist, page) from each song
      - Support multiple TOC types from config (by title, by artist, custom)
      - Handle hierarchical breaks (e.g., group by first letter)
    </task>
    <!-- More tasks (6 total)... -->
  </implementation-details>
</feature>
```

## Key Technical Approaches

### TOC with Page Numbers
```perl
# Generate TOC structure
my @toc_entries = map {
    {
        title => $_->{meta}->{title}[0],
        artist => $_->{meta}->{artist}[0] // '',
        page_ref => "song-$_->{songindex}",  # Reference for paged.js
    }
} @{$sb->{songs}};

# Template renders with placeholder
# JavaScript fills in page numbers after paged.js renders
```

### Even Page Mirroring
```css
/* Odd pages (right) - page number on right */
@page :right {
  @bottom-left { content: string(song-title); }
  @bottom-right { content: counter(page); }
}

/* Even pages (left) - page number on left */
@page :left {
  @bottom-left { content: counter(page); }
  @bottom-right { content: string(song-title); }
}
```

### Song Sorting
```perl
use Unicode::Collate;

my $collator = Unicode::Collate->new();
@{$sb->{songs}} = sort {
    $collator->cmp(
        $a->{meta}->{title}[0] // '',
        $b->{meta}->{title}[0] // ''
    )
} @{$sb->{songs}};
```

## Testing Strategy

Each feature includes tests in `testing/html5paged/`:

```perl
# Example TOC test
my $sb = generate_songbook([
    'song1.cho', 'song2.cho', 'song3.cho'
], {
    'html5.paged.toc.enabled' => 1,
});

ok($sb =~ /table of contents/i, "TOC header present");
ok($sb =~ /Song 1/, "Song 1 in TOC");
ok($sb =~ /Song 2/, "Song 2 in TOC");
# Verify page numbers after paged.js renders
```

## Configuration Examples

### Enable TOC
```json
{
  "contents": [
    {
      "name": "table_of_contents",
      "fields": ["songindex", "title"],
      "label": "Table of Contents",
      "omit": false
    }
  ]
}
```

### Enhanced Headers/Footers
```json
{
  "pdf": {
    "formats": {
      "first": {
        "title": ["", "", ""],
        "footer": ["", "", ""]
      },
      "title": {
        "footer": ["%{title}", "%{page}", "%{artist}"]
      },
      "default": {
        "footer": ["", "%{page}", ""]
      },
      "even": {
        "footer": ["%{page}", "", "%{title}"]
      }
    }
  }
}
```

### Dual-Page Layout
```json
{
  "html5": {
    "paged": {
      "twoside": true,
      "binding_offset": "0.5cm"
    }
  }
}
```

## Timeline

**Week 1**: TOC + Page Number Integration  
**Week 2**: Headers/Footers + Odd/Even Pages  
**Week 3**: Song Sorting + Page Alignment + TOC Breaks  
**Week 4**: Polish + Low Priority Features

**Total**: 33-47 hours over 4 weeks

## Success Criteria

### Must Have (Ship Blockers)
- [ ] TOC generated with accurate page numbers
- [ ] Headers/footers support format variants
- [ ] Odd/even pages styled for binding
- [ ] Tests pass for all features
- [ ] Documentation complete

### Should Have (v2.0)
- [ ] Song sorting works
- [ ] Page alignment to right pages
- [ ] TOC hierarchical breaks

### Nice to Have (Future)
- [ ] Cover pages
- [ ] Keyboard diagrams
- [ ] Debug mode

## Questions?

Refer to the detailed documents:
- `HTML5_PRINT_EXECUTIVE_SUMMARY.md` - Overview and timeline
- `HTML5_PRINT_FEATURE_ANALYSIS.md` - Feature comparison
- `HTML5_PRINT_IMPLEMENTATION_PLAN.xml` - Full implementation details
