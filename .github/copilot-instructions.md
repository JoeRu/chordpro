# ChordPro Development Guide for AI Agents

## Project Overview
ChordPro is a Perl-based lyrics and chords formatting program that generates professional sheet music from text files. It parses ChordPro format files (`.cho`) and outputs to multiple backends: PDF, HTML, HTML5, Markdown, LaTeX, JSON, and Text.

**Core Language**: Perl 5.26+ with modern features (signatures, Object::Pad for OOP)
**Main Entry**: `lib/ChordPro.pm` - orchestrates parsing and output generation
**Architecture**: Parser → Song Structure → Backend Renderer

### HTML5 Backend Architecture
The HTML5 backend (`lib/ChordPro/Output/HTML5.pm`) supports multiple output modes:
- **Responsive Mode** (default): Fluid layout for screens, mobile-friendly
- **Screen Mode**: Fixed layout optimized for screen display
- **Print Mode**: Paginated output with paged.js integration for PDF generation

Configuration: Set via `html5.mode` config (values: "responsive", "screen", "print")

**Helper Modules**:
- `lib/ChordPro/Output/HTML5Helper/FormatGenerator.pm` - Converts PDF format specs to CSS @page rules
- `lib/ChordPro/Output/ChordDiagram/SVG.pm` - Generates SVG chord diagrams

## Critical Architecture Patterns

### Song Processing Pipeline
1. **Parse** (`lib/ChordPro/Song.pm`, ~2800 lines): Reads ChordPro directives and builds structured representation
2. **Transform**: Apply transposition, substitutions, chord parsing via `lib/ChordPro/Chords/*.pm`
3. **Render**: Backend-specific output via `lib/ChordPro/Output/*.pm`

### Output Backend Architecture
**Two distinct patterns exist** - understand which to follow:

**Legacy Pattern** (PDF.pm, HTML.pm):
- Monolithic functions with 500+ line if/elsif chains
- Hard to maintain; avoid for new backends

**Modern Pattern** (Markdown.pm, HTML5.pm, ChordPro.pm):
- Object::Pad classes inheriting from `ChordProBase`
- Handler registry pattern: `%element_handlers` maps element types to methods
- Each directive type has dedicated handler method
- Example from Markdown.pm:
  ```perl
  class ChordPro::Output::Markdown :isa(ChordPro::Output::ChordProBase) {
      method render_songline($element) { ... }
      method render_chorus($element) { ... }
  }
  ```

**When creating new output backends**: Use Object::Pad pattern, inherit from ChordProBase, implement required methods.

### Configuration System
- JSON-based configs in `lib/ChordPro/res/config/`
- Loaded via `lib/ChordPro/Config.pm`
- Access via global `$config` and `$options` variables
- Config hierarchy: builtin → sysconfig → userconfig → CLI options
- Test configs: Use `ChordPro::Config::configurator()` without args for minimal setup
- **Backend selection via config**: Each output format can override its default backend via the `module` key:
  - `html.module`: Select backend for .html files ("HTML" legacy or "HTML5" modern)
  - Example: `{ "html": { "module": "HTML5" } }` makes .html files use HTML5 backend
  - Backend selection happens after config load (see `lib/ChordPro.pm` lines 197-200)
  - Command-line `--generate` flag always takes precedence over config

## AI Agent Output Conventions

**Generated test files**: Place in `testing/` directory (not `t/` - that's for production tests / unit tests)
**Generated documentation**: Place in `ai-docs/` directory

These directories keep AI-generated content separate from the main codebase until reviewed and promoted.

## Development Workflows

### Building & Testing
```bash
# Initial setup (generates Makefile from Makefile.PL)
perl Makefile.PL

# Run tests via GNUmakefile (preferred - sets PERL5LIB correctly)
make test          # Standard tests in t/
make tests         # Include extended tests in xt/

# Run specific test
prove -bv t/105_chords.t
```

### Running ChordPro During Development
```bash
# Single file - using installed script (if available)
./script/chordpro input.cho -o output.pdf

# Single file - development mode (no install needed)
perl -Ilib script/chordpro.pl input.cho -o output.pdf

# Generate songbook from multiple files (creates single output)
perl -Ilib script/chordpro.pl songs/*.cho -o songbook.pdf
perl -Ilib script/chordpro.pl song1.cho song2.cho song3.cho -o output.pdf

# Specify output backend
perl -Ilib script/chordpro.pl --generate=HTML5 songs/*.cho -o songbook.html
perl -Ilib script/chordpro.pl --generate=Markdown songs/*.cho -o songbook.md

# Quick inspection outputs
perl -Ilib script/chordpro.pl --generate=PDF input.cho -o output.pdf
perl -Ilib script/chordpro.pl --generate=HTML5 input.cho -o output.html
```

### Test Structure
- Tests in `t/` follow pattern: `###_feature.t` (numbered for execution order)
- Use `ChordPro::Testing` module which:
  - Auto-chdir to `t/` directory
  - Exports Test::More functions
  - Provides `is_deeply` for song structure comparison
- Tests compare generated output in `t/out/` against reference in `t/ref/`
- Test parameter pattern from `t/00_basic.pl`:
  ```perl
  my ($num, $basic, $backend) = @::params;
  @ARGV = ("--no-default-configs", "$basic.cho", "--output=out/$out");
  ::run();
  ok(!differ("out/$out", "ref/$out"));
  ```

### Testing HTML5 Backend
- `generate_song()` returns song HTML only (no headers/CSS), `generate_songbook()` returns full document
- For song-level tests, check for content presence rather than full document structure
- Example test pattern:
  ```perl
  my $html = $backend->generate_song($song);
  ok($html && length($html) > 0, "Output generated");
  like($html, qr/expected-content/, "Contains expected content");
  ```
- Backend modules must handle both chord info as blessed objects (runtime) and plain hash refs (tests)
- HTML5 backend supports multiple modes (responsive, screen, print) via `html5.mode` config

### Chord System
- **Multiple notation systems**: standard (C, D, E...), solfege (Do, Re, Mi...), Nashville (1, 2, 3...), Roman (I, II, III...)
- Parser in `lib/ChordPro/Chords/Parser.pm` - understands transposition between systems
- Chord appearance (font, rendering) in `lib/ChordPro/Chords/Appearance.pm`
- Each song tracks used chords in order: `@used_chords` in Song.pm
- Configuration key: `$config->{notes}->{sharp}` defines the interval system

## Project-Specific Conventions

### Perl Patterns
```perl
# Modern OOP - Object::Pad (v0.818+)
use Object::Pad;
class MyClass :isa(BaseClass) {
    field $private_field;
    method my_method($arg) { ... }
}

# Signatures (Perl 5.26+)
use feature qw( signatures );
no warnings "experimental::signatures";
sub mysub ( $param1, $param2 ) { ... }

# Global variables (accessible in all packages)
our $options;  # CLI options
our $config;   # Configuration hash
```

### Element Structure
Songs are arrays of element hashes:
```perl
{
  type => "songline",      # Type: songline, chorus, verse, comment, etc.
  chords => [...],         # Chord positions and names
  phrases => [...],        # Lyric segments between chords
  context => "chorus",     # Context (verse, chorus, tab, grid)
}
```

### Naming Conventions
- Backends: `lib/ChordPro/Output/BackendName.pm` with `generate_songbook()` and `generate_song()` methods
- Tests: Numeric prefix indicates category (100s = basic, 300s = config, 80s = pagination)
- Config keys use kebab-case: `chords-under`, `lyrics-only`, `single-space`

## Key Integration Points

### ABC & LilyPond Music Notation
- Delegates to external processors: `lib/ChordPro/Delegate/ABC.pm`, `lib/ChordPro/Delegate/Lilypond.pm`
- ABC uses bundled `abc2svg` (JavaScript via Perl's JavaScript::QuickJS)
- LilyPond requires external `lilypond` binary
- Both output SVG embedded in final document

### Resource Resolution
- `ChordPro::Paths` handles resource lookup (configs, fonts, icons)
- Resources in `lib/ChordPro/res/` - fonts, configs, icons, abc/lilypond delegates
- Use `CP->findres($name, class => "type")` for resource loading

### GUI (wxChordpro)
- Separate wxWidgets frontend: `lib/ChordPro/Wx.pm`, `script/wxchordpro`
- Shares core parsing/rendering with CLI
- Not required for core ChordPro development

## Common Pitfalls

1. **Don't mix output patterns**: Use Object::Pad for new backends, not procedural style
2. **Config access timing**: Config loaded after option parsing; tests use `configurator()` to initialize
3. **Chord transposition**: Song.pm handles it during parsing; backends receive transposed chords
4. **Context management**: Song parser tracks context (`verse`, `chorus`, `tab`, `grid`); backends must respect it
5. **Line info tracking**: `$config->{settings}->{lineinfo}` controls source line tracking in output
6. **SVG rendering**: SVG `<line>` elements require explicit `stroke="#color"` attributes - CSS classes alone are insufficient for visibility
7. **CSS sizing for HTML outputs**: Use `em` units (e.g., `width: 4em`) instead of fixed pixels for better scalability across different font sizes
8. **Module flexibility**: When creating reusable modules, support both blessed objects and plain hash refs for maximum compatibility (check `ref($obj) eq 'HASH'` vs object methods)
9. **Template consolidation**: HTML5 templates organized in unified structure: `html5/` for normal output, `html5/paged/` for paged.js features. Paged mode reuses shared CSS (typography, variables) while adding paged-specific templates (string-set, page-setup, layout)
10. **Module organization**: Reusable output modules go in `lib/ChordPro/Output/ComponentName/`, NOT `lib/ChordPro/lib/` (Perl's @INC won't find them there)
11. **CRITICAL - Backend Structurization**: Never call `$song->structurize()` in `lib/ChordPro.pm` central dispatch - each backend must handle its own structurization needs. Some backends (ChordPro.pm output) require unstructured songs with `start_of_`/`end_of_` directives. Call `$song->structurize()` in backend's `generate_song()` method if needed (HTML5.pm does this)
12. **CRITICAL - Build After Changes**: After modifying Perl modules, always run `make` before testing. The `blib/` directory caches compiled code - tests will use old code until rebuilt. Test failures showing old behavior often mean you forgot to rebuild
13. **Test Promotion Workflow**: Develop new tests in `testing/` directory, then move to production (`t/`) after verification. Use numbered prefixes matching test category (e.g., `t/html5paged/04_formats.t`)
14. **CRITICAL - Song Metadata Access**: Metadata is stored in `$song->{meta}` hash, NOT at top level. Always use `$song->{meta}->{artist}` not `$song->{artist}`. Reference `lib/ChordPro/Output/ChordPro.pm` (lines 77-95) for canonical metadata access pattern. All metadata fields are arrayrefs, even single-value fields like album/duration - iterate or use `[0]` index
15. **Object::Pad BUILD Blocks**: Field initialization requires BUILD blocks. Can't just declare `field $svg_generator;` and use it - must add `BUILD { $svg_generator = Module->new(...); }` for proper initialization. Object::Pad fields are NOT automatically initialized
16. **Test Mock Objects**: Never create mock song objects with hardcoded structures in unit tests. Use real .cho files with proper parsing via `ChordPro::Song->new()->parse_file()`. Mock objects bypass critical initialization and don't match actual runtime structures
17. **CRITICAL - Restricted Hash Handling**: JSON::Relaxed creates locked/restricted hashes in `$config`. Must handle carefully:
   - Use `eval { $hash->{key} } // default` to safely access potentially non-existent keys
   - Clone to plain hashes before passing to Template::Toolkit: `{ %$hashref }` or extract to temp vars first
   - NEVER do `$template_vars->{colors} = $config->{css}->{colors} // {}` - the `// {}` returns empty restricted hash
   - Correct pattern: `my $cfg = eval { $config->{css}->{colors} } // {}; $vars->{colors} = { %$cfg };`
   - **Phase 4 Lesson**: Must wrap EACH key access in eval{}, not just top-level hash. Wrong: `eval { $config->{pdf} }->{theme}`. Right: `eval { $config->{pdf}->{theme} }`
   - Errors like "Attempt to access disallowed key 'X' in a restricted hash" mean you passed restricted hash to template
18. **Template::Toolkit Integration**: When adding template support (following LaTeX.pm pattern):
   - MUST add config section with `template_include_path` array (e.g., `html5.paged.template_include_path`)
   - Initialize in BUILD block: `$template_engine = Template->new({ INCLUDE_PATH => [...], INTERPOLATE => 1 })`
   - Test environment needs fallback paths - `CP->findres("templates")` returns undef in tests from `t/` directory
   - Template INCLUDE directives need full path relative to INCLUDE_PATH: `[% INCLUDE 'html5paged/base.tt' %]` NOT `[% INCLUDE 'base.tt' %]`
   - Always run `make` after template changes - templates may be cached in `blib/`
   - **Phase 4 Lesson**: Template syntax for dash-containing keys: Use `.item('key-name')` NOT `.'key-name'`. Example: `theme.item('foreground-medium')` not `theme.'foreground-medium'`
19. **Template Array Checks**: Template::Toolkit array checks must avoid numeric comparisons on empty values:
   - **GOOD**: `[% IF subtitle.0 %]` (checks first element exists) or `[% IF meta.artist %]` (truthiness)
   - **BAD**: `[% IF subtitle.size > 0 %]` or `[% IF meta.artist.size > 0 %]` (causes "Argument '' isn't numeric" warnings)
   - Reason: Empty metadata arrays can contain empty strings, causing numeric comparison warnings
   - Pattern applies to all metadata fields: artist, composer, subtitle, album, etc.
   - **Phase 4 Lesson**: This pattern discovered through actual runtime warnings, not code inspection
20. **Chord Object Type Handling**: Chords appear as multiple types throughout rendering pipeline:
   - **Hash refs** (parse-time): `{name => "C", ...}`
   - **ChordPro::Chords::Appearance objects** (runtime): Use `->chord_display()` method
   - **Generic chord objects**: Use `->name()` method
   - **Standard pattern** (cascading checks with fallback):
     ```perl
     if (ref($chord) eq 'HASH') { $name = $chord->{name} }
     elsif ($chord->can('chord_display')) { $name = $chord->chord_display }
     elsif ($chord->can('name')) { $name = $chord->name }
     else { $name = "$chord" }  # Stringify fallback
     ```
   - Apply this pattern in `render_songline`, `render_gridline`, and chord display code
21. **Grid Element Structure**: Chord grids have specific element structure requiring specialized rendering:
   - **Structure**: `{type => 'gridline', tokens => [], margin => {...}, comment => {...}}`
   - **Tokens**: Array of `{class => 'chord'|'bar'|'repeat1'|'repeat2'|'slash'|'space', chord => ..., symbol => ...}`
   - **Classes**: `bar` (|, ||, |., |:, :|, etc.), `chord`, `repeat1` (%), `repeat2` (%%), `slash` (/), `space` (.)
   - **Margin**: Optional `{chord => ..., text => ...}` for left-side text/chords
   - **Comment**: Optional `{chord => ..., text => ...}` for right-side comments
   - Reference: `lib/ChordPro/Song.pm` lines 1037-1180 (`decompose_grid` method)
   - Markdown backend example: `lib/ChordPro/Output/Markdown.pm` lines 221-227, 345-347
22. **Template Organization**: Separate CSS templates from structural HTML templates for clarity:
   - **Structure**: CSS templates in `templates/{backend}/css/` subdirectory
   - **HTML5**: `lib/ChordPro/res/templates/html5/` (structural), `html5/css/` (styling)
   - **HTML5 Paged**: `lib/ChordPro/res/templates/html5/paged/` (paged-specific templates), `html5/paged/css/` (paged CSS)
   - **Shared Templates**: Paged mode reuses `html5/css/typography.tt` and `html5/css/variables.tt`
   - **Base template includes**: Reference css/ subdirectory: `[% INCLUDE 'html5/css/typography.tt' %]` or `[% INCLUDE 'html5/paged/css/page-setup.tt' %]`
   - **Config references**: Use full paths: `"html5/css/base.tt"`, `"html5/paged/css/base.tt"`
   - Users can distinguish template types by directory without inspecting file contents
23. **CRITICAL - Config Resolution for Template Variables**: When passing config values to templates:
   - **Problem**: Restricted hashes + nested access + template variable assignment creates errors
   - **Wrong Pattern**: `$vars->{theme} = eval { $config->{pdf} }->{theme} // {};` (theme gets restricted hash)
   - **Correct Pattern**: Each key level needs separate eval{}: `my $theme = eval { $config->{pdf}->{theme} } // {}; $vars->{theme} = { %$theme };`
   - **Why**: The eval{} only protects the immediate hash access, not nested keys; must eval{} full path then clone
   - **Phase 4 Discovery**: Manifests as "Attempt to access disallowed key" in Template::Toolkit processing
   - **Resolution Methods**: Create _resolve_* methods that extract, validate, and clone config data before template processing
24. **Backend Module Override Pattern**: ChordPro supports config-driven backend selection via `{format}.module` key:
   - **Pattern**: Config key `{format}.module` overrides default backend after config load (ChordPro.pm lines 197-200)
   - **Example**: `{"html": {"module": "HTML5"}}` makes .html files use HTML5 backend instead of legacy HTML
   - **Timing**: File extension sets initial backend (lines 125-151), config overrides later (lines 197-200)
   - **Precedence**: CLI `--generate` flag > `{format}.module` config > file extension default
   - **Applies to all formats**: html, pdf, latex, etc. - consistent pattern across backends
   - **Use Case**: Allows users to opt-in to new backends without changing file extensions or CLI flags
   - **Backward Compatibility**: Defaults unchanged; users explicitly opt-in via config
   - **Phase 5 Discovery**: Feature already existed, just needed documentation

## Recent Architectural Efforts
The project is migrating from monolithic backends (PDF.pm - 2800 lines) to modular Object::Pad-based architecture. See `Design/ARCHITECTURE_COMPARISON.md` and `Design/HTML5_*.md` for detailed rationale. **Follow the Markdown.pm pattern for new work**, not PDF.pm.

### Recent Additions (Dec 2025 - Feb 2026)

#### SVG Chord Diagrams (Dec 2025)
HTML5 backend supports inline SVG chord diagrams:
- Implementation in `lib/ChordPro/Output/HTML5.pm` methods: `render_chord_diagrams()`, `generate_chord_diagram_svg()`
- Standalone reusable module: `lib/ChordPro/Output/ChordDiagram/SVG.pm`
- Diagrams sized at `4em` width for scalability with font size
- Respects config settings: `diagrams.show`, `diagrams.sorted`, `diagrams.suppress`
- Tests: `t/html5/` test suite validates chord diagram rendering
- **Integration Pattern**: Use `field $svg_generator;` with `BUILD { $svg_generator = ChordPro::Output::ChordDiagram::SVG->new(escape_fn => sub { $self->escape_text(@_) }); }` in Object::Pad classes

#### HTML5 Paged Mode - Headers & Footers (Dec 2025)
Full headers/footers configuration support for paged output reusing PDF's `pdf.formats` config:
- **Format Parsing**: `_generate_format_rules()` in `lib/ChordPro/Output/HTML5.pm` parses format specs (e.g., `"%{title}||%{page}"`)
- **CSS @page Margin Boxes**: Generates `@top-left`, `@bottom-center`, etc. with content from metadata
- **Metadata via Data Attributes**: Song title/artist/album exposed as `data-title`, `data-artist`, etc. attributes on elements
- **CSS string-set Pattern**: Must use `string-set: song-title attr(data-title);` NOT `content()` for metadata capture
- **Even/Odd Pages**: Format variants (`first`, `title`, `even`, `odd`) with automatic left/right margin box swapping for even pages
- **Three-Part Format**: Format strings split by `||` into left/center/right parts, mapped to appropriate margin boxes
- Implementation: Paged mode methods add metadata attributes and generate format CSS rules
- Tests: `t/html5paged/` test suite (50+ tests total)
- Config example:
  ```json
  {
    "pdf": {
      "formats": {
        "default": {
          "footer": ["", "%{page}", ""]
        },
        "title": {
          "footer": ["%{title}", "%{page}", "%{artist}"]
        }
      }
    }
  }
  ```

#### Enhanced Metadata & Layout Directives (Dec 2025)
Complete metadata and layout directive support in HTML5 backend:
- **Metadata Fields**: arranger, copyright, lyricist, duration now fully supported in ChordProBase and HTML5
- **Layout Directives**: new_page, new_physical_page, column_break, columns implemented as CSS styling
- **Access Pattern**: Must use `$song->{meta}->{field}` NOT `$song->{field}` - metadata lives in separate hash
- **Array Iteration**: All metadata is stored as arrayrefs, even single values: `foreach my $val (@{$meta->{field}}) { ... }`
- Reference implementation: `lib/ChordPro/Output/ChordPro.pm` lines 77-95 shows canonical metadata access
- Tests: `t/75_html5.t` validates backend functionality
#### Template::Toolkit Refactoring (HTML5 - Dec 2025)
HTML5 backend fully refactored to use Template::Toolkit (following LaTeX.pm pattern):
- **Architecture**: Zero hardcoded HTML/CSS in backend code, all markup in separate template files
- **Template Location**: 
  - HTML5 Normal: `lib/ChordPro/res/templates/html5/` (structural: songbook.tt, song.tt, songline.tt, comment.tt, image.tt, chord-diagrams.tt)
  - HTML5 CSS: `lib/ChordPro/res/templates/html5/css/` (styling: base.tt, typography.tt, songlines.tt, sections.tt, tab-grid.tt, chord-diagrams.tt, print-media.tt, body-page.tt, variables.tt)
  - HTML5 Paged: `lib/ChordPro/res/templates/html5/paged/` (songbook.tt, song.tt)
  - HTML5 Paged CSS: `lib/ChordPro/res/templates/html5/paged/css/` (base.tt, string-set.tt, page-setup.tt, layout.tt, print-media.tt)
  - **Shared**: Paged mode reuses `html5/css/typography.tt` and `html5/css/variables.tt`
- **Config Section**: `html5.templates.{css|songbook|song|songline|comment|image|chord_diagrams}`, `html5.paged.templates.{css|songbook|song}`
- **Integration Pattern**: 
  - Template helper: `_process_template($name, $vars)` method handles all template processing
  - Element renderers: Individual methods for each type
  - Dispatch pattern: `_process_song_body()` iterates elements, calls appropriate renderer
  - Main methods: `generate_song()`, `generate_songbook()`, `render_chord_diagrams()` all template-driven
- **Grid Rendering Exception**: `render_gridline()` uses direct HTML generation (grid structure too complex for templates)
- **Benefits**: Modular organization, user-customizable templates via config, easier maintenance
- **Lessons**: Template array checks must use `.0` or truthiness (not `.size > 0`), chord objects require cascading type checks
- Tests: `t/75_html5.t` validates functionality

#### Phase 4: PDF Config Compatibility (Dec 2025)
HTML5 paged mode supports PDF configuration options via hybrid precedence:
- **Hybrid Config**: `html5.paged.* > pdf.* > defaults` allows PDF configs to work with HTML5 paged output
- **Theme Colors**: `pdf.theme.foreground`, `pdf.theme.background`, etc. → CSS variables
- **Spacing Multipliers**: `pdf.spacing.lyrics`, `pdf.spacing.chords`, etc. → CSS spacing
- **Chorus Styling**: `pdf.chorus.bar.offset/width/color` → CSS border properties
- **Grid Styling**: `pdf.diagrams.symbols.color`, `pdf.chordgrid.volta.color` → CSS colors
- **Page Spacing**: `pdf.headspace`, `pdf.footspace` → @page margin sizing
- **Implementation Pattern**: 
  - Config resolution methods: `_resolve_theme_colors()`, `_resolve_spacing()`, `_resolve_chorus_styles()`, `_resolve_grid_styles()`
  - Each method extracts config, validates, converts to CSS-friendly format
  - Methods handle restricted hashes safely with eval{} wrapping
  - Results passed to templates as plain hashes with CSS variable mappings
- **Color Conversion**: `_convert_color_to_css()` handles color format normalization (#RGB, #RRGGBB, named colors)
- **Template Integration**: All Phase 4 values exposed as CSS variables in variables.tt templates
- **Critical Lessons Learned**:
  - Must eval{} each nested key access separately (not just top-level)
  - Template syntax for dashed keys: `.item('key-name')` not `.'key-name'`

#### Step 5: Config-Driven Backend Selection (Feb 2026)
Documented existing `{format}.module` config pattern for backend selection:
- **Feature Discovery**: ChordPro.pm already implemented module-based backend override (lines 197-200)
- **Documentation Only**: No code changes needed - feature existed but was undocumented
- **Config Pattern**: `{"html": {"module": "HTML5"}}` selects HTML5 backend for .html files
- **Use Case**: Users can opt-in to modern HTML5 backend without changing file extensions
- **Timing**: File extension → initial backend (lines 125-151), config → override (lines 197-200)
- **Backward Compatible**: Defaults to "HTML" (legacy); users explicitly opt-in to "HTML5"
- **Universal Pattern**: Same mechanism works for all formats (pdf.module, latex.module, etc.)
- **Implementation**: Updated `chordpro.json` config comments, added copilot-instructions.md section
- **Testing**: All 108 tests pass; manual verification with config files confirms functionality
- **Lesson**: Always check for existing patterns before implementing new features - saves time and maintains consistency
- Reference: `ai-docs/STEP5_IMPLEMENTATION_SUMMARY.md`, `ai-docs/changes-bugs.md` (Step 5)
  - Clone restricted hashes before template processing: `{ %$hashref }`
  - Unit tests for resolution methods avoid template path complexity
- Tests: `t/html5paged/07_phase4_config.t` (23 tests), comprehensive config resolution coverage
- Documentation: `docs/content/ChordPro-Configuration-HTML5.md` (Phase 4 section, 186 lines)

#### Template Consolidation (Feb 2026)
Unified HTML5 template structure for better organization and maintainability:
- **Consolidation**: Merged `HTML5Helper/` templates into `html5/paged/` subfolder structure
- **Benefits**: Single template hierarchy, reduced duplication, clearer organization
- **Structure**: 
  - `html5/` - Normal/responsive output templates (15 files)
  - `html5/paged/` - Paged output specific templates (7 files)
  - Shared CSS: typography.tt and variables.tt used by both modes
- **Eliminated Duplicates**: Removed duplicate typography.tt and variables.tt from paged templates
- **Path Updates**: All config references updated from `HTML5Helper/` to `html5/paged/`
- **Backward Compatibility**: Config paths updated, no API changes
- **Critical Lessons**:
  - Template consolidation requires careful INCLUDE path updates
  - Shared templates reduce maintenance burden and ensure consistency
  - Always verify tests pass after structural changes
  - Directory structure should reflect logical relationships (paged as subset of html5)
- Reference: `ai-docs/TEMPLATE_CONSOLIDATION_PLAN.md`
- Tests: All HTML5 tests pass after consolidation