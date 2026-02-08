# ChordPro Development Guide for AI Agents

## Project Overview
ChordPro is a Perl 5.26+ lyrics/chords formatting program. Parses `.cho` files → structured song representation → renders via backend (PDF, HTML5, HTML, Markdown, LaTeX, JSON, Text, MMA).

- **Entry point**: [lib/ChordPro.pm](lib/ChordPro.pm) — orchestrator (CLI options, backend selection, config loading)
- **Parser**: [lib/ChordPro/Song.pm](lib/ChordPro/Song.pm) (~2800 lines) — builds element-array structures
- **Backends**: [lib/ChordPro/Output/](lib/ChordPro/Output/) — one module per format
- **Config**: [lib/ChordPro/res/config/chordpro.json](lib/ChordPro/res/config/chordpro.json) (1425 lines)
- **Version**: 6.090_040 (development), see [lib/ChordPro/Version.pm](lib/ChordPro/Version.pm)

## Build and Test
```bash
perl Makefile.PL            # Generate Makefile (first time)
make                        # REQUIRED after any .pm or template change (blib/ caches)
make test                   # Run t/*.t tests
make tests                  # Include xt/ extended tests
prove -bv t/105_chords.t    # Single test
perl -Ilib script/chordpro.pl --generate=HTML5 input.cho -o output.html  # Dev run
```
**Critical**: Always `make` before `prove`. Tests use `blib/` which caches old code.

## Architecture

### Pipeline: Parse → Transform → Render
1. `Song.pm` parses directives into element arrays: `{type => "songline", chords => [...], phrases => [...]}`
2. Transposition/chord parsing via `Chords/*.pm` during parse
3. Backend renders via `generate_songbook()` / `generate_song()`

### Backend Patterns
| Pattern | Backends | Use for new work? |
|---------|----------|-------------------|
| **Modern** (Object::Pad + ChordProBase) | HTML5.pm, Markdown.pm, Meta.pm | **Yes** |
| **Legacy** (procedural) | PDF.pm, HTML.pm, Text.pm, ChordPro.pm, LaTeX.pm | No |

Modern pattern — follow [lib/ChordPro/Output/Markdown.pm](lib/ChordPro/Output/Markdown.pm):
```perl
use Object::Pad;
class ChordPro::Output::MyBackend :isa(ChordPro::Output::ChordProBase) {
    field $my_field;
    BUILD { $my_field = ...; }  # Object::Pad fields need BUILD
    method render_songline($element) { ... }
}
```

### Config System
- JSON hierarchy: builtin → sysconfig → userconfig → CLI `--define`
- Access: `$config->{key}`, `$options->{flag}`
- **Restricted hashes** (JSON::Relaxed): `eval { $config->{pdf}->{theme} } // {}` — wrap each level in eval{}
- Clone before Template::Toolkit: `{ %$hashref }`
- Backend selection: `{format}.module` config overrides default (e.g., `{"html":{"module":"HTML5"}}`)

### Song Element Types
`songline`, `chorus`, `verse`, `tab`, `gridline`, `comment`, `comment_italic`, `comment_box`, `image`, `empty`, `set`, `delegate`, `control`

Metadata in `$song->{meta}->{field}` (NOT top-level). All values are arrayrefs.

### Key Modules
| Module | Purpose |
|--------|---------|
| [Song.pm](lib/ChordPro/Song.pm) | Parser, structurize(), decompose_grid() |
| [Config.pm](lib/ChordPro/Config.pm) | Config loading, configurator() |
| [Chords/Parser.pm](lib/ChordPro/Chords/Parser.pm) | Multi-notation chord parsing (standard/latin/nashville/roman) |
| [Output/ChordProBase.pm](lib/ChordPro/Output/ChordProBase.pm) | Abstract base with element dispatch |
| [Output/HTML5.pm](lib/ChordPro/Output/HTML5.pm) | Modern HTML5 backend (Template::Toolkit, 3 modes) |
| [Output/PDF/Song.pm](lib/ChordPro/Output/PDF/Song.pm) | PDF song renderer (2800+ lines) |
| [Paths.pm](lib/ChordPro/Paths.pm) | Resource resolution: `CP->findres()` |
| [Delegate/ABC.pm](lib/ChordPro/Delegate/ABC.pm) | ABC notation → SVG (bundled abc2svg via QuickJS) |
| [Output/ChordDiagram/SVG.pm](lib/ChordPro/Output/ChordDiagram/SVG.pm) | SVG chord diagram generator |

## Project Conventions

### Chord Objects — Cascading Type Check
```perl
if (ref($chord) eq 'HASH') { $name = $chord->{name} }
elsif ($chord->can('chord_display')) { $name = $chord->chord_display }
elsif ($chord->can('name')) { $name = $chord->name }
else { $name = "$chord" }
```

### Test Conventions
- Numbered files: `t/###_feature.t` (100s=core, 70s=backends, 80s=html5, 190s=bugfixes)
- `ChordPro::Testing` auto-chdirs to `t/`, exports Test::More
- Compare output: `t/out/` vs `t/ref/`
- Never mock songs — use real `.cho` files with `ChordPro::Song->new()->parse_file()`
- AI tests: develop in `testing/`, promote to `t/`
- Subdirs: `t/html5/` (9 tests), `t/html5paged/` (10 tests)

### File Placement
- Backends: `lib/ChordPro/Output/Name.pm`
- Reusable modules: `lib/ChordPro/Output/Component/` (NOT `lib/ChordPro/lib/`)
- Templates: `lib/ChordPro/res/templates/html5/` (structural), `html5/css/` (styling), `html5/paged/` (paged mode)
- AI docs: `ai-docs/`; AI tests: `testing/`

### HTML5 Backend Specifics
- 3 modes: responsive (default), screen, print — via `html5.mode` config
- Template::Toolkit driven — zero hardcoded HTML in backend code
- Paged mode uses paged.js for CSS @page rules, headers/footers
- SVG chord diagrams at `4em` width for scalability
- Grid rendering uses direct HTML (too complex for templates)
- Structurization: call `$song->structurize()` in backend's `generate_song()`, never in ChordPro.pm

## Critical Pitfalls
1. **Rebuild**: `make` after every `.pm`/template change — `blib/` caches old code
2. **Metadata**: `$song->{meta}->{artist}` not `$song->{artist}` — always arrayrefs
3. **Restricted hashes**: `eval { $config->{a}->{b} } // {}` then clone `{ %$hash }`
4. **Template dashed keys**: `.item('key-name')` not `.'key-name'` in TT2
5. **Template array checks**: `[% IF list.0 %]` not `[% IF list.size > 0 %]`
6. **BUILD blocks**: Object::Pad fields need explicit `BUILD { }` initialization
7. **SVG stroke**: `<line>` elements need `stroke="#color"` — CSS classes insufficient
8. **Backend structurize**: Each backend owns its structurization, never central dispatch

## AI Agent Output Conventions
- Always analyze the problem and plan before writing code
- Track work in `ai-docs/feature-bugs.xml` using the XML template in [CLAUDE.md](CLAUDE.md)
- Generated tests → `testing/`; generated docs → `ai-docs/`
- Follow the implementation plan template for all features/bugs (see CLAUDE.md for XML schema)
