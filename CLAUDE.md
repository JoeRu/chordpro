# CLAUDE.md - ChordPro Development Guide

This is the primary agent instruction file. .github/copilot-instructions.md points here.

## Project Overview

ChordPro is a Perl-based lyrics and chords formatting program that generates professional sheet music from text files (`.cho` format). It outputs to PDF, HTML5, HTML, Markdown, LaTeX, JSON, Text, and MMA.

- **Language**: Perl 5.26+ with modern features (signatures, Object::Pad for OOP)
- **Entry point**: `lib/ChordPro.pm` orchestrates parsing and output generation
- **Architecture**: Parser (`Song.pm`) → Song Structure → Backend Renderer (`Output/*.pm`)
- **Version**: See `lib/ChordPro/Version.pm`

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
- AI-generated tests go in `testing/` first, then promote to `t/` after review and delete the remains if it `testing/`

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

# Implementation Plan Workflow

## Overview

This project uses a structured XML-based implementation plan to track all features, bugs, refactoring, and tech-debt. The plan is the single source of truth for what exists, what's planned, and what's been decided against.

A separate `overview.xml` captures the project's architectural baseline – structure, dependencies, existing features, and security concerns. It is created during the initial code analysis and kept in sync as items are archived.

## Files & Locations

| File | Purpose | When updated |
|---|---|---|
| `ai-docs/overview.xml` | Project architecture, dependencies, environments, security, completed features | Initial analysis + every archival |
| `ai-docs/feature-bugs.xml` | Active and pending items (features, bugs, refactoring, tech-debt) | Every interaction that changes scope or code |
| `ai-docs/` | All other markdown and planning documents | As needed |

> **Note**: `ai-docs/overview.xml` and `ai-docs/feature-bugs.xml` are the current sources of truth.
> Always read both before starting work.

## Initial Code Analysis

When first encountering a project or after major structural changes, perform a full code analysis before any other work:

### Steps

1. **Scan the codebase**: directory structure, languages, frameworks, config files, package manifests
2. **Identify architecture**: patterns, layers, entry points, data flow
3. **Catalog dependencies**: system requirements (runtime, OS) and external dependencies (APIs, databases, services)
4. **Map existing features**: what the code already does – derive from routes, modules, tests, README
5. **Note interfaces**: inbound (APIs, UIs, webhooks) and outbound (external calls, queues, file outputs)
6. **Check for security concerns**: auth mechanisms, exposed secrets, input validation, known vulnerability patterns
7. **Detect environments**: dev/staging/prod configurations, environment variables, deploy scripts

### Output

Generate `ai-docs/overview.xml` with the full project baseline:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project-overview>
  <metadata>
    <title>Project Title</title>
    <version>1.0</version>
    <analyzed>2026-02-08</analyzed>
    <updated>2026-02-08</updated>
    <repository>https://github.com/org/repo</repository>
  </metadata>

  <architecture>
    <description>Overall architecture description</description>
    <patterns>
      <pattern>e.g. MVC, Event-Driven</pattern>
    </patterns>
    <system-requirements>
      <requirement>e.g. Node.js >= 20</requirement>
    </system-requirements>
    <external-dependencies>
      <dependency>e.g. PostgreSQL 16, Stripe API</dependency>
    </external-dependencies>
    <interfaces>
      <interface type="inbound|outbound">Description</interface>
    </interfaces>
    <design-decisions>
      <decision date="2026-02-08">Decision and rationale</decision>
    </design-decisions>
  </architecture>

  <environments>
    <environment name="dev">Setup notes</environment>
    <environment name="staging">Details</environment>
    <environment name="prod">Details</environment>
  </environments>

  <security>
    <concern>
      <threat>Threat description</threat>
      <risk>LOW|MEDIUM|HIGH|CRITICAL</risk>
      <vulnerability>Potential vulnerability</vulnerability>
      <mitigation>How addressed</mitigation>
    </concern>
  </security>

  <!-- Completed features – populated from initial analysis and archival -->
  <completed-features>
    <feature id="CF1" completed="2026-02-08">
      <title>Feature title</title>
      <description>What it does</description>
      <files>
        <file>path/to/relevant/file</file>
      </files>
    </feature>
  </completed-features>
</project-overview>
```

Also update `ai-docs/feature-bugs.xml` with any identified issues, improvements, or TODOs as items with `status="PENDING"`.

If `overview.xml` already exists, **read it** at the start of every session for project context.

## Core Rules

### 1. Always Check Before Acting

Before implementing ANY user request (feature, bug, change, question about the codebase):

1. **Read** `ai-docs/overview.xml` (project context)
2. **Read** `ai-docs/feature-bugs.xml` (active items)
3. **Search** for existing items that match the request (by title, description, related files, or affected area)
4. **Decide**:
   - **Existing item found** → update that item (status, tasks, details) rather than creating a duplicate
   - **No match** → create a new item with `status="PENDING"`
5. **Inform the user** which item ID was created or updated

### 2. Always Update the Plan

Every interaction that involves code changes, bug reports, or feature discussion **must** result in an update to `feature-bugs.xml`. This includes:

- New feature requests → new `<item type="feature" status="PENDING">`
- Bug reports → new `<item type="bug" status="PENDING">`
- Scope changes → update existing item's tasks, acceptance-criteria, or justification
- Implementation progress → update status (`PENDING` → `APPROVED` → `IN_PROGRESS` → `DONE`)
- Bugs found during implementation → new `<item type="bug">` with `depends-on` referencing the parent item
- Verification results → fill `<r>` block with outcome, observations, lessons-learned, files

### 3. Default Status is PENDING

All new items are created with `status="PENDING"`. The user must explicitly approve before implementation begins. Never skip to `APPROVED` or `IN_PROGRESS` without user confirmation.

Status lifecycle:
```
PENDING ──→ APPROVED ──→ IN_PROGRESS ──→ DONE
   │
   └──→ DENIED
```

### 4. ID Assignment

- Read the current highest ID in `feature-bugs.xml`
- Assign the next sequential integer
- Sub-items use the parent ID as prefix for tasks: item 15 → tasks `15.1`, `15.2`, etc.

### 5. Complexity & Decomposition

Estimate complexity for every new item:
- **S** = isolated change, single file, < 1 day
- **M** = few files, clear scope, 1–3 days
- **L** = cross-cutting, multiple components, 3–7 days
- **XL** = epic-level → **must** be decomposed into sub-items with `parent="ID"`

If an item is XL: create the epic with `<acceptance-criteria>` and create sub-items with individual tasks. Do not put tasks directly on XL items.

### 6. Branch Naming Convention

Branches follow the pattern `{type}/item-{ID}-{slug}`:

```
feature/item-12-oauth-integration
bug/item-20-auth-race-condition
refactoring/item-35-cleanup-token-cache
tech-debt/item-41-migrate-to-v2-api
```

Rules:
- **Slug**: max 5 words, kebab-case, derived from the item title
- **Sub-items**: use the parent's branch (they work on the same feature)
- **Auto-fill**: populate `<branch>` in XML when status changes to `APPROVED`
- **No branch** for DENIED or PENDING items

### 7. Changelog

Update the `<changelog>` block in `feature-bugs.xml` **once per interaction** (not per item change). Group all changes from the same interaction into a single entry.

Format:
```xml
<changelog>
  <entry date="2026-02-08">Items 12, 14 created (PENDING). Item 3 → IN_PROGRESS.</entry>
  <entry date="2026-02-07">Item 10 → DONE, archived. Bug item 20 created from verification.</entry>
</changelog>
```

No entry for read-only interactions (Claude reads the plan but changes nothing).

### 8. Max Items per Interaction

Soft limit: **5 items** created or updated per response.

- **Create**: max 5 new items
- **Update**: max 5 existing items
- **Mixed**: max 5 total (creates + updates combined)
- **Overflow**: list remaining items as preview, ask user whether to continue
- **Exception**: initial project analysis (first-time plan creation) has no limit

### 9. Archival

Completed and denied items are moved to the `<archive>` block in `feature-bugs.xml` and simultaneously registered in `overview.xml`.

**When to archive:**
- `DONE` items: when the item AND all its sub-items are DONE, AND no active item has a `depends-on` referencing it
- `DENIED` items: immediately (no dependencies possible)

**Archival process (both files updated in one step):**

1. **Move** the item from the active section to `<archive>` in `feature-bugs.xml`:
   ```xml
   <archive>
     <item id="1" status="DONE" archived="2026-02-08" ...>
       <!-- full item preserved for history -->
     </item>
   </archive>
   ```

2. **Add** a `<completed-features>` entry in `overview.xml` (for DONE items only):
   ```xml
   <completed-features>
     <feature id="CF-1" completed="2026-02-08" source-item="1">
       <title>Feature title (from item)</title>
       <description>Brief summary of what was built and why</description>
       <files>
         <file>path/to/file (from item's result block)</file>
       </files>
     </feature>
   </completed-features>
   ```

3. **Update** `<metadata><updated>` in `overview.xml` with the current date

4. **Update** architecture, dependencies, or security sections in `overview.xml` if the archived item introduced changes to any of these

**Do not archive** items that are still referenced by active `depends-on`.

### 10. Security by Default

Security is not a separate concern – it is part of every item's risk assessment.

**For every item** (feature, bug, refactoring, tech-debt), evaluate during creation or approval:

1. **Does this item introduce, modify, or remove any of the following?**
   - Authentication or authorization logic
   - User input handling (forms, APIs, file uploads, query parameters)
   - Data storage or transmission (databases, caches, APIs, cookies, tokens)
   - Third-party integrations or external API calls
   - File system access or process execution
   - Cryptographic operations or secret management
   - CORS, CSP, or other security headers
   - User-facing error messages (information disclosure risk)

2. **If yes to any**: add `security="true"` to the item and include a `<security-impact>` block:
   ```xml
   <item id="N" type="feature" status="PENDING" priority="HIGH" security="true">
     ...
     <security-impact>
       <category>AUTH|INPUT|DATA|NETWORK|CRYPTO|ACCESS|DISCLOSURE</category>
       <threat>What could go wrong from a security perspective</threat>
       <mitigation>How the implementation addresses this</mitigation>
     </security-impact>
     ...
   </item>
   ```

3. **If no**: no `security` attribute needed – but reassess if scope changes during implementation.

**Security categories reference:**

| Category | Covers |
|---|---|
| `AUTH` | Authentication, authorization, session management, token handling |
| `INPUT` | Injection (SQL, XSS, command), validation, sanitization |
| `DATA` | Storage encryption, PII handling, data leakage, backup security |
| `NETWORK` | TLS, CORS, CSP, SSRF, API security, rate limiting |
| `CRYPTO` | Key management, hashing, signing, random number generation |
| `ACCESS` | File permissions, path traversal, privilege escalation |
| `DISCLOSURE` | Error messages, stack traces, debug endpoints, version exposure |

Multiple categories can apply to one item. List all relevant ones.

**Security bugs** found during `/security` audits or implementation are created with:
```xml
<item id="N" type="bug" status="PENDING" priority="HIGH" security="true">
  <title>[SECURITY] Description of the vulnerability</title>
  <security-impact>
    <category>INPUT</category>
    <threat>Unsanitized user input in search query allows SQL injection</threat>
    <mitigation>Use parameterized queries for all database access</mitigation>
  </security-impact>
  ...
</item>
```

Security bugs default to `priority="HIGH"` minimum. `CRITICAL` if exploitable without authentication or if it affects data integrity/confidentiality.

### 11. Security Updates on Archival

When archiving items that have `security="true"`, the `<security>` section in `overview.xml` **must** be updated:

- **DONE security items**: evaluate whether the mitigation resolved an existing concern or introduced a new security posture. Update or add `<concern>` entries accordingly.
- **DENIED security items**: if the denial leaves a known vulnerability unaddressed, add or keep the corresponding `<concern>` with a note that mitigation is outstanding.

The `<security>` section in `overview.xml` must always reflect the **current** security posture of the project – not just the initial analysis.

## XML Structure Quick Reference

```xml
<!-- Simple feature or bug -->
<item id="N" type="feature|bug|refactoring|tech-debt" status="PENDING" priority="CRITICAL|HIGH|MEDIUM|LOW" complexity="S|M|L|XL">
  <title>Short descriptive title</title>
  <branch>type/item-N-slug</branch>
  <justification>Why this is needed</justification>
  <depends-on>comma-separated item IDs or empty</depends-on>
  <tasks>
    <task id="N.1">Task description</task>
  </tasks>
  <verification>
    <tests>
      <test type="unit|integration|e2e|human">
        <file>path/to/test</file>
        <description>What is tested</description>
        <assertions>Expected behavior</assertions>
      </test>
    </tests>
  </verification>
  <r>
    <outcome>DONE|PROBLEM</outcome>
    <observations></observations>
    <lessons-learned></lessons-learned>
    <files><file>path/to/file</file></files>
  </r>
</item>

<!-- Epic (XL) with acceptance criteria -->
<item id="N" type="feature" status="PENDING" priority="HIGH" complexity="XL">
  <title>Epic title</title>
  <acceptance-criteria>
    <criterion id="AC1">Measurable criterion</criterion>
  </acceptance-criteria>
  <risks>
    <risk>Risk and mitigation</risk>
  </risks>
</item>

<!-- Sub-item of epic -->
<item id="N+1" type="feature" status="PENDING" priority="HIGH" complexity="M" parent="N">
  <title>Sub-feature of epic</title>
  <depends-on>N</depends-on>
  ...
</item>

<!-- Complex bug with analysis -->
<item id="N" type="bug" status="PENDING" priority="HIGH" complexity="L">
  <steps-to-reproduce>
    <step order="1">Step description</step>
  </steps-to-reproduce>
  <expected-result>What should happen</expected-result>
  <analysis>
    <hypothesis id="H1" status="OPEN|CONFIRMED|REJECTED">Description</hypothesis>
    <root-cause>When identified</root-cause>
    <affected-files><file>path</file></affected-files>
  </analysis>
</item>

<!-- Security-relevant item (any type) -->
<item id="N" type="bug" status="PENDING" priority="HIGH" complexity="M" security="true">
  <title>[SECURITY] SQL injection in search endpoint</title>
  <justification>Unsanitized input reaches database query</justification>
  <security-impact>
    <category>INPUT</category>
    <threat>Attacker can extract or modify database contents via crafted search query</threat>
    <mitigation>Replace string concatenation with parameterized queries</mitigation>
  </security-impact>
  <tasks>
    <task id="N.1">Refactor search query to use parameterized statements</task>
    <task id="N.2">Add input validation layer for search parameters</task>
  </tasks>
  ...
</item>
```

## Workflow Summary

```
First encounter (no overview.xml)
     │
     ▼
Scan codebase → generate overview.xml + feature-bugs.xml
     │
     ▼
─────────────────────────────────────────────────────
     │
Every subsequent request
     │
     ▼
Read overview.xml + feature-bugs.xml
     │
     ├─ Existing item? ──→ Update item (status, tasks, details)
     │
     └─ New request? ──→ Create item with status="PENDING"
                              │
                              ▼
                    Inform user of item ID
                              │
                              ▼
                    Wait for user approval
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
              APPROVED              DENIED
                    │                   │
                    ▼                   ▼
              Implement          Archive immediately
                    │
                    ▼
              Verify & update <r> block
                    │
                    ▼
              Status → DONE
                    │
                    ▼
              Archive if no active dependents
                    │
                    ├──→ Move to <archive> in feature-bugs.xml
                    └──→ Add to <completed-features> in overview.xml
```

## Slash Commands

The user can use slash commands as shortcuts. When a message starts with a slash command, Claude skips the usual conversational back-and-forth and executes the action directly.

### Item Creation Commands

| Command | Action | Default type | Default priority |
|---|---|---|---|
| `/bug <description>` | Create bug item | `bug` | `HIGH` |
| `/feature <description>` | Create feature item | `feature` | `MEDIUM` |
| `/refactor <description>` | Create refactoring item | `refactoring` | `MEDIUM` |
| `/debt <description>` | Create tech-debt item | `tech-debt` | `LOW` |

**Optional inline modifiers** – append after description:

| Modifier | Effect | Example |
|---|---|---|
| `!critical` `!high` `!medium` `!low` | Override priority | `/bug Login fails !critical` |
| `!security` | Mark as security-relevant | `/bug XSS in comments !security` |
| `@<ID>` | Set `depends-on` | `/feature Token refresh @11` |
| `^<ID>` | Set `parent` (sub-item of epic) | `/feature OAuth callback ^10` |

**Examples:**
```
/bug Login fails silently when OAuth token expires
→ Creates: item type="bug", priority="HIGH", status="PENDING"

/feature Add dark mode support !low
→ Creates: item type="feature", priority="LOW", status="PENDING"

/bug Race condition in token cache !critical @11
→ Creates: item type="bug", priority="CRITICAL", depends-on="11", status="PENDING"

/feature Session management ^10 @11
→ Creates: item type="feature", parent="10", depends-on="11", status="PENDING"
```

### Item Management Commands

| Command | Action |
|---|---|
| `/approve <ID> [ID...]` | Set status to APPROVED, generate branch name |
| `/deny <ID> [reason]` | Set status to DENIED, archive immediately |
| `/status <ID>` | Show current status, tasks, and dependencies of an item |
| `/list [filter]` | List items – filter by status, type, or priority |
| `/archive` | Archive all eligible DONE/DENIED items, update security section in overview.xml |

**Examples:**
```
/approve 12 13 14
→ Sets items 12, 13, 14 to APPROVED, generates branch names

/deny 15 Out of scope for MVP
→ Sets item 15 to DENIED with justification, archives immediately

/status 12
→ Shows: Item 12 "OAuth Integration" | APPROVED | priority HIGH | depends-on: none | 3 tasks (0 done)

/list pending
→ Lists all PENDING items with ID, title, priority, complexity

/list bug high
→ Lists all HIGH priority bugs

/list security
→ Lists all items with security="true"

/archive
→ Archives all eligible items, updates both XML files including security section
```

### Security Commands

| Command | Action |
|---|---|
| `/security` | Full security audit of the current codebase |
| `/security <area>` | Focused audit on a specific area (e.g. `/security auth`, `/security api`) |
| `/security status` | Show current security posture: open concerns, unresolved security items, coverage |

**`/security` audit process:**

1. **Read** `overview.xml` security section (known concerns) and all items with `security="true"` in `feature-bugs.xml`
2. **Scan** the codebase against security categories (AUTH, INPUT, DATA, NETWORK, CRYPTO, ACCESS, DISCLOSURE)
3. **Cross-reference** with existing security items to avoid duplicates
4. **Create bug items** for each finding:
   - `type="bug"`, `security="true"`, `status="PENDING"`
   - Title prefixed with `[SECURITY]`
   - `priority="HIGH"` minimum, `CRITICAL` if exploitable without auth or affects data integrity
   - Full `<security-impact>` block with category, threat, and mitigation
5. **Update** `<security>` section in `overview.xml` with any new concerns discovered
6. **Report** summary to user: total findings, by category, by severity, new vs. already tracked

**Example:**
```
/security
→ Scanning codebase against 7 security categories...
→ Found 4 issues:
  - Item 25 [SECURITY] [INPUT] SQL injection in /api/search (CRITICAL) — NEW
  - Item 26 [SECURITY] [AUTH] Missing rate limit on /auth/login (HIGH) — NEW
  - Item 27 [SECURITY] [DISCLOSURE] Stack traces in production error responses (HIGH) — NEW
  - Item 28 [SECURITY] [DATA] User passwords logged in debug mode (CRITICAL) — NEW
→ Updated overview.xml security section
→ 4 items created as PENDING – /approve to begin fixes

/security auth
→ Focused scan on authentication and authorization...
→ Found 2 issues in auth area.

/security status
→ Security posture:
  - 3 open concerns in overview.xml
  - 2 security bugs PENDING, 1 IN_PROGRESS, 4 DONE (archived)
  - Uncovered areas: CRYPTO (no items), NETWORK (last audit: 30 days ago)
```

### Plan Overview Commands

| Command | Action |
|---|---|
| `/plan` | Show summary: counts by status, type, priority + next actionable items |
| `/overview` | Show architecture summary from overview.xml |
| `/init` | Run initial code analysis (creates both XML files) |

### Command Processing Rules

1. **Always read both XML files first** – even for slash commands
2. **Still check for duplicates** – `/bug` must search before creating
3. **Still respect the 5-item limit** – `/approve 1 2 3 4 5 6 7` processes first 5, asks for confirmation
4. **Still update changelog** – every command that modifies the plan gets a changelog entry
5. **Confirm creation** – after processing, show: item ID, title, type, priority, status
6. **Unknown commands** – if a slash command is not recognized, list available commands

## Important Reminders

- **Never implement without checking both XML files first**
- **Never create duplicate items** – always search existing items before adding
- **Never skip PENDING** – the user decides what gets built
- **Always assess security impact** – every item gets a security check during risk evaluation
- **Always tag security items** – `security="true"` + `[SECURITY]` title prefix + `<security-impact>` block
- **Always update `<r>` after implementation** – outcomes and lessons-learned are mandatory
- **Always archive to both files** – overview.xml stays in sync including security posture
- **Keep the XML valid** – malformed XML breaks the workflow
- **Respect the 5-item limit** – ask before processing more
- **Update changelog once per interaction** – grouped, not per item
- When in doubt about priority, complexity, or security impact, **ask the user**
