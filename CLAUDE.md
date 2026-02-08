# CLAUDE.md - ChordPro Development Guide

## Project Overview

ChordPro is a Perl-based lyrics and chords formatting program that generates professional sheet music from text files (`.cho` format). It outputs to PDF, HTML5, HTML, Markdown, LaTeX, JSON, Text, and MMA.

- **Language**: Perl 5.26+ with modern features (signatures, Object::Pad for OOP)
- **Entry point**: `lib/ChordPro.pm` orchestrates parsing and output generation
- **Architecture**: Parser (`Song.pm`) → Song Structure → Backend Renderer (`Output/*.pm`)
- **Version**: See `lib/ChordPro/Version.pm`

## AI Agent Output Conventions

Allways Analyze the problem and plan the solution before writing code. 
update for all phases a document in ai-docs/feature-bugs.xml like the following template with the results of the implementation and verification of each feature or bug in the plan, such as performance metrics, compatibility issues, user feedback, and lessons learned during the implementation process. This document will serve as a comprehensive record of the development process and can be used for future reference and learning.

```xml:

<?xml version="1.0" encoding="UTF-8"?>
<implementation-plan>
  <metadata>
    <title>my-title</title>
    <version>2.0</version>
    <date>2026-02-06</date>
    <status></status>
    <summary>
    </summary>
  </metadata>

  <architecture>
    <description>
    Overall architecture description
    </description>
    <architecture-patterns>
      <pattern>Pattern Name</pattern>
    </architecture-patterns>
    <dependencies>
    <!-- optional: Ask the user to test the following: If the system dependencies are met and add possible missing ones as feature to implement; Check if the system is able to implement at all. -->
      <dependency>Software or Tool or Interface Dependency description</dependency>
    </dependencies>
    <interfaces>    
      <interface type="Inbound|Outbound">Interface Description</interface>
    </interfaces>
    <design-decisions>
      <decision>Design decision description</decision>
    </design-decisions>
     <existing-features>
    <!-- move features that are marked by DONE here -->
      <feature>
        <title></title>
        <description>
        </description>
        <relevant-files>
        List of relevant files for that feature.
        </relevant-files>
        <tests>
        <test id=N type="Unit|human|semi-automatic|integration">
          description and tasks of the test-case.
        </test>
        </test>
        </tests>
      </feature>
    </existing-features> 
    <security>
      <security-issue>
        <thread></thread>
        <potential-vulnerability></potential-vulnerability>
      </security-issue>
    </security>
  </architecture>

<!-- Repeat this <feature-or-bug> block for each feature or bug in the plan - sort it by criticality and dependency -->
<feature-or-bug id="N">
  <title>Feature Name</title>
  <branch>Branch for possible parallel implementation</branch>
  <priority>CRITICAL|HIGH|MEDIUM|LOW</priority>
  <implementation-decision>implement|denied</implementation-decision>
  <reason>Justification</reason>
  <depends-on>Feature IDs this depends on</depends-on>
  <implementation-risks>
    <risk>Risk description and mitigation</risk>
  </implementation-risks>
  <implementation-details>
    <task id="1">Task description</task>
  </implementation-details>  
  <!--  verification has to be done imidiatly after implementation - try to fix problems in the process and further verifications when needed during implementation and add them to the plan -->
  <verification>
    <steps-to-verify>
      <step order="1">Manual verification step</step>
    </steps-to-verify>
    <unit-tests>
      <unit-test possible="YES|NO" reason="Short Reason for the possibility or impossibility of the test">
        <file></file>
        <description>Test description</description>
        <assertions>Expected behavior</assertions>
      </unit-test>
    </unit-tests>
    <!-- optional : add only for documentation of bugs found during implementation and verification, not for all bugs found in the system. -->
    <bugs>
        <bug id="1" status="OPEN|FIXED|WONTFIX">
            <description>Bug description</description>
            <steps-to-reproduce>
            <step order="1">Step to reproduce the bug</step>
            </steps-to-reproduce>
            <expected-result>Expected result if the bug is fixed</expected-result>
        </bug>
    </bugs>
    <!-- optional test only a human can do. -->
    <human-tests> 
        <human-test id="1">
        Describe what to do and what to expect as result. 
        </human-test>
    </human-tests>
  </verification>
  <!-- fill in the results and lessons learned after implementation and verification -->
  <result>
      <my-result>DONE|PROBLEM</my-result>
      <list-of-results>
        Fill with the results of the implementation, such as performance metrics, compatibility issues, or user feedback.
      </list-of-results>
      <lessons-learned>
        Fill with insights gained during the implementation, such as what worked well, what challenges were faced, and how they were overcome.
      </lessons-learned>
      <relevant-files>
        <file>List of relevant files that were changed or created during implementation or are highly relevant to the feature.</file>
      </relevant-files>
    </result>
</feature-or-bug>

  <denied-features>
    <feature id="D1">
      <title></title>
      <reason>

      </reason>
    </feature>

  <!-- ================================================================== -->
  <!-- SUMMARY STATISTICS                                                  -->
  <!-- ================================================================== -->

  <summary-statistics>
    <total-features>18</total-features>
    <implement>12</implement>
    <denied>6</denied>
    <by-priority>
      <critical>2</critical>
      <high>4</high>
      <medium>8</medium>
      <low>4</low>
    </by-priority>
    <by-branch>
      <branch-a name="Core Infrastructure + Songbook">6</branch-a>
      <branch-b name="Content Rendering + Layout">8</branch-b>
      <branch-c name="CSS/Styling">4</branch-c>
    </by-branch>
  </summary-statistics>    
</implementation-plan>
```

**Generated test files**: Place in `testing/` directory (not `t/` - that's for production tests / unit tests)
**Generated documentation**: Place in `ai-docs/` directory

These directories keep AI-generated content separate from the main codebase until reviewed and promoted.

Update this instructions when critical lessons are learned.

## Build & Test

```bash
# Initial setup (generates Makefile)
perl Makefile.PL

# Build (REQUIRED after modifying Perl modules - blib/ caches compiled code)
make

# Run tests
make test          # Standard tests in t/
make tests         # Include extended tests in xt/

# Run specific test
prove -bv t/105_chords.t

# Run ChordPro during development
perl -Ilib script/chordpro.pl input.cho -o output.pdf
perl -Ilib script/chordpro.pl --generate=HTML5 input.cho -o output.html
perl -Ilib script/chordpro.pl --generate=Markdown input.cho -o output.md
```

**Critical**: Always run `make` after modifying Perl modules before testing. The `blib/` directory caches compiled code and tests use it. Test failures showing old behavior usually mean a rebuild is needed.

## Code Layout

```
lib/ChordPro.pm              # Main orchestrator
lib/ChordPro/Song.pm         # Parser - largest module (~2800 lines)
lib/ChordPro/Config.pm       # Configuration loader
lib/ChordPro/Config/Data.pm  # Auto-generated from chordpro.json (don't edit by hand)
lib/ChordPro/Output/         # Backend renderers
lib/ChordPro/Chords/         # Chord parsing and notation systems
lib/ChordPro/Delegate/       # External format processors (ABC, LilyPond)
lib/ChordPro/Paths.pm        # Resource path resolution
lib/ChordPro/res/            # Resources: configs, templates, fonts
lib/ChordPro/res/config/     # JSON configuration files
lib/ChordPro/res/templates/  # Template::Toolkit templates (html5/, html5/paged/)
script/chordpro.pl           # CLI entry point
script/wxchordpro.pl         # GUI entry point (wxWidgets)
t/                           # Production test suite
xt/                          # Extended/author tests
testing/                     # AI-generated tests (separate from production)
ai-docs/                     # AI-generated documentation
```

## Architecture

### Song Processing Pipeline

1. **Parse** (`Song.pm`): Reads ChordPro directives, builds structured representation
2. **Transform**: Transposition, chord parsing via `Chords/*.pm`
3. **Render**: Backend-specific output via `Output/*.pm`

### Output Backend Patterns

**Modern pattern** (use for new backends): Object::Pad classes inheriting from `ChordProBase` with handler registry pattern. See `Output/Markdown.pm`, `Output/HTML5.pm`.

```perl
class ChordPro::Output::MyBackend :isa(ChordPro::Output::ChordProBase) {
    method render_songline($element) { ... }
    method render_chorus($element) { ... }
}
```

**Legacy pattern** (avoid for new work): Monolithic procedural functions. See `Output/PDF.pm`, `Output/HTML.pm`.

### Configuration System

- JSON configs in `lib/ChordPro/res/config/`
- Hierarchy: builtin → sysconfig → userconfig → CLI options
- Access via global `$config` and `$options`
- Config keys use kebab-case: `chords-under`, `lyrics-only`
- Backend selection: `{format}.module` config key overrides default (e.g., `{"html": {"module": "HTML5"}}`)
- **Restricted hashes**: JSON::Relaxed creates locked hashes. Use `eval { $config->{nested}->{key} } // default` for safe access. Clone before passing to Template::Toolkit: `{ %$hashref }`.

### Song Element Structure

Songs are arrays of element hashes:

```perl
{
  type    => "songline",   # songline, chorus, verse, comment, image, gridline, etc.
  chords  => [...],        # Chord positions
  phrases => [...],        # Lyric segments between chords
  context => "chorus",     # verse, chorus, tab, grid
}
```

Metadata lives in `$song->{meta}` (NOT top-level). All metadata fields are arrayrefs.

## Key Conventions

### Perl Patterns

```perl
# Modern OOP (Object::Pad 0.818+)
use Object::Pad;
class MyClass :isa(BaseClass) {
    field $private_field;
    BUILD { $private_field = ...; }  # Required for field initialization
    method my_method($arg) { ... }
}

# Signatures
use feature qw( signatures );
no warnings "experimental::signatures";
sub mysub ( $param1, $param2 ) { ... }
```

### Chord Object Handling

Chords appear as multiple types in the rendering pipeline. Use cascading checks:

```perl
if (ref($chord) eq 'HASH') { $name = $chord->{name} }
elsif ($chord->can('chord_display')) { $name = $chord->chord_display }
elsif ($chord->can('name')) { $name = $chord->name }
else { $name = "$chord" }
```

### Test Conventions

- Tests in `t/` follow `###_feature.t` naming (numbered for execution order)
- Use `ChordPro::Testing` module (auto-chdir to `t/`, exports Test::More)
- Tests compare generated output in `t/out/` against reference in `t/ref/`
- Never create mock song objects; use real `.cho` files with `ChordPro::Song->new()->parse_file()`
- AI-generated tests go in `testing/` first, then promote to `t/` after review

### File Placement

- New backends: `lib/ChordPro/Output/BackendName.pm`
- Reusable output modules: `lib/ChordPro/Output/ComponentName/` (NOT `lib/ChordPro/lib/`)
- New tests: develop in `testing/`, promote to `t/` after verification
- AI-generated docs: `ai-docs/`

## Common Pitfalls

1. **Forgetting to rebuild**: Run `make` after any module change before testing
2. **Metadata access**: Use `$song->{meta}->{artist}` not `$song->{artist}`; metadata values are always arrayrefs
3. **Restricted hash errors**: Wrap nested config access in `eval {}`, clone before template use
4. **Structurization**: Never call `$song->structurize()` in central dispatch (`ChordPro.pm`); each backend handles its own needs
5. **Object::Pad fields**: Must use BUILD blocks for initialization; fields are NOT auto-initialized
6. **Template array checks**: Use `[% IF subtitle.0 %]` not `[% IF subtitle.size > 0 %]` to avoid numeric comparison warnings
7. **Template dashed keys**: Use `.item('key-name')` not `.'key-name'` in Template::Toolkit
8. **SVG rendering**: `<line>` elements need explicit `stroke="#color"` attributes; CSS classes alone won't work
9. **CSS sizing**: Use `em` units instead of fixed pixels for HTML outputs
