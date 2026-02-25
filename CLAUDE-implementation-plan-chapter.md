# Implementation Plan Workflow

## Overview

This project uses a structured XML-based implementation plan to track all features, bugs, refactoring, and tech-debt. The plan is the single source of truth for what exists, what's planned, and what's been decided against.

A separate `overview.xml` captures the project's architectural baseline – structure, dependencies, existing features, and security concerns. It is created during the initial code analysis and kept in sync as items are archived.

## Files & Locations

| File | Purpose | When updated |
|---|---|---|
| `ai-docs/overview.xml` | Project architecture, dependencies, environments, security, completed features | Initial analysis + every archival |
| `ai-docs/overview-features-bugs.xml` | **Index**: `<item-ref>` per active item (id, status, title, branch, depends-on, `planned-files`) + sprints/releases/blockers + last 30 changelog entries | Every interaction that changes scope or code |
| `ai-docs/items/{NNNN}.xml` | Full item content (tasks, verification, `<affected-files>`, workflow-log, `<r>`) — one file per active item | Created on item creation; updated on each lifecycle transition |
| `ai-docs/items/archive/{NNNN}.xml` | Archived items (moved here by `/archive`) | On each archival |
| `ai-docs/lessons-learned.md` | Aggregated lessons extracted from DONE items | Created on first `/archive` with non-trivial lessons |
| `ai-docs/implementation-plan-template.xml` | Schema reference (do not edit) | Never |
| `ai-docs/` | All other markdown and planning documents | As needed |

**Legacy format:** If `ai-docs/items/` does not exist, items are stored inline in `overview-features-bugs.xml` (flat format — still supported). Run `/update` to migrate.

**Session Start:** Load `overview.xml` and `overview-features-bugs.xml` (index only — fast). Load individual `ai-docs/items/{NNNN}.xml` files **on demand**:
- `/status N` or `/run N` → load `items/NNNN.xml`
- `/archive` → load all `items/` files with DONE or DENIED status
- Archive lookup: load `items/archive/NNNN.xml` when an ID is not found in the active index

**Also read:** `CLAUDE-roles-chapter.md` for role definitions, capability tables, and the end-to-end workflow swimlane.

## Code Analysis

Code analysis runs in two modes: **initial** (first encounter) and **update** (verification of existing XMLs). Both modes execute the same analysis steps but differ in how results are processed.

| Trigger | Mode | Precondition |
|---|---|---|
| No `overview.xml` exists | **Initial** | Automatic on first encounter |
| `/init_overview` | **Initial** | Force re-creation (backs up existing files first) |
| `/update` | **Update** | Both XML files must already exist |

### Steps (executed in both modes)

1. **Scan the codebase**: directory structure, languages, frameworks, config files, package manifests
2. **Identify architecture**: patterns, layers, entry points, data flow
3. **Catalog dependencies**: system requirements (runtime, OS) and external dependencies (APIs, databases, services)
4. **Map existing features**: what the code already does – derive from routes, modules, tests, README
5. **Assess feature completeness**: for each discovered feature, evaluate:
   - `completeness`: FULL (fully understood) | PARTIAL (gaps identified) | UNKNOWN (exists but not analyzed)
   - `test-coverage`: TESTED (automated tests cover core behavior) | PARTIAL (some tests, gaps identified) | NONE (no tests found) | UNKNOWN (not assessed)
   - `dependencies`: what other features or external systems does it rely on
   - `gaps`: specific areas that are unclear or unmapped
6. **Note interfaces**: inbound (APIs, UIs, webhooks) and outbound (external calls, queues, file outputs)
7. **Check for security concerns**: auth mechanisms, exposed secrets, input validation, known vulnerability patterns
8. **Detect environments**: dev/staging/prod configurations, environment variables, deploy scripts

### Feature Completeness & Reference Items

Every existing feature discovered during analysis is recorded in `overview.xml` under `<completed-features>` with a `completeness` and `test-coverage` rating.

**If a feature is not FULL + TESTED**, create a **reference item** in `overview-features-bugs.xml`:

```xml
<item id="42" type="refactoring" status="PENDING" priority="MEDIUM" complexity="M" ref-feature="CF2">
  <title>[REF] Payment processing – complete feature mapping and add tests</title>
  <justification>Feature CF2 has completeness=PARTIAL, test-coverage=NONE. 
    Changes to related code risk breaking payment flow without detection.</justification>
  <tasks>
    <task id="42.1">Map webhook retry logic and document behavior</task>
    <task id="42.2">Map refund flow end-to-end</task>
    <task id="42.3">Write integration tests for checkout flow</task>
    <task id="42.4">Write integration tests for webhook handling</task>
  </tasks>
  <verification>
    <tests>
      <test type="integration">
        <file>tests/payments/test_checkout.py</file>
        <description>Checkout flow end-to-end</description>
        <assertions>Payment created, confirmed, receipt sent</assertions>
      </test>
    </tests>
  </verification>
  <r>
    <outcome></outcome>
    <files><file></file></files>
  </r>
</item>
```

**Reference item rules:**
- `type="refactoring"` – the goal is understanding and safeguarding, not changing behavior
- Title prefixed with `[REF]` for easy identification
- `ref-feature="CF-ID"` attribute links back to the feature in `overview.xml`
- The corresponding feature in `overview.xml` gets a `ref-item="ID"` attribute pointing to this item
- Tasks focus on: mapping unknowns, documenting behavior, writing tests
- Priority based on risk: features touched by active items get `HIGH`, others `MEDIUM` or `LOW`
- When the reference item is DONE: update the feature in `overview.xml` to `completeness="FULL"` and `test-coverage="TESTED"`

**Priority escalation**: if any active item (feature, bug, refactoring) touches files belonging to a feature with `completeness != FULL` or `test-coverage == NONE`:
1. **Warn the user** that changes affect an incompletely mapped feature
2. **Recommend** approving the corresponding reference item first
3. If no reference item exists yet, **create one** as PENDING

### Mode: Initial (no XMLs exist or `/init_overview`)

When no `overview.xml` exists, or the user explicitly runs `/init_overview`:

1. Execute all analysis steps above
2. **Generate** `ai-docs/overview.xml` with the full project baseline
3. **Generate** `ai-docs/overview-features-bugs.xml` with discovered issues, TODOs, and `[REF]` items as PENDING
4. If files already exist (`/init_overview` on existing project): **back up** existing files as `overview.xml.bak` and `overview-features-bugs.xml.bak` before overwriting

### Mode: Update (`/update`)

When both XML files already exist and the user runs `/update`, perform a **verification pass** that compares the current codebase against the existing XMLs:

**Step 1 – Drift detection on overview.xml:**

| Check | Compare | Action on mismatch |
|---|---|---|
| Architecture | Codebase patterns vs. `<architecture>` | Update description, patterns, design-decisions |
| System requirements | package.json / requirements.txt / Dockerfile vs. `<system-requirements>` | Add missing, flag removed |
| External dependencies | Code imports + config vs. `<external-dependencies>` | Add missing, flag removed |
| Interfaces | Routes, endpoints, webhooks vs. `<interfaces>` | Add missing, flag removed |
| Environments | Config files, env vars vs. `<environments>` | Update details |
| Security | Current code vs. `<security>` concerns | Add new concerns, verify mitigations still apply |

**Step 2 – Feature verification:**

For each feature in `<completed-features>`:
1. **Verify files still exist** – if files were deleted or renamed, flag as `STALE`
2. **Check for new files** that belong to the feature but aren't listed
3. **Re-assess completeness** – has code changed since last analysis? Upgrade or downgrade rating
4. **Re-assess test-coverage** – have tests been added or removed?
5. **Check gaps** – are previously identified gaps still open?

For features discovered in codebase but **not yet in overview.xml**:
1. **Add** as new `<completed-features>` entry
2. **Assess** completeness and test-coverage
3. **Create** `[REF]` item if not FULL + TESTED

**Step 3 – Item verification on overview-features-bugs.xml:**

For each active item:
1. **Verify referenced files** still exist and are relevant
2. **Check depends-on** references – are dependencies still valid?
3. **Check parent** references – does the parent still exist and make sense?
4. **Flag stale items** – items that have been PENDING or APPROVED for a long time without progress

**Step 4 – Report:**

Present a verification summary to the user:

```
/update
→ Scanning codebase and verifying XMLs...

overview.xml:
  ✓ Architecture – no changes
  ⚠ Dependencies – added: redis (found in requirements.txt, not in XML)
  ⚠ Security – new concern: API key in config/settings.py not in .gitignore
  
Features:
  ✓ CF1 "User Auth" – files OK, tests OK, completeness FULL
  ⚠ CF2 "Payment processing" – completeness PARTIAL → PARTIAL (gaps unchanged)
  ✗ CF3 "Email notifications" – STALE: src/email/sender.py deleted
  + CF4 "Rate limiting" – NEW: discovered in src/middleware/rate_limit.py (PARTIAL, NONE)
    → Created [REF] item 45 (PENDING)

Items:
  ✓ 12 active items verified
  ⚠ Item 8 "Add CSV export" – PENDING since 2026-01-15 (24 days), consider /deny or /approve
  ⚠ Item 14 – depends-on item 7 which is DENIED → needs reassignment

→ Updated overview.xml (2 changes)
→ Created 1 new [REF] item, flagged 1 stale feature, 2 item warnings
```

### Output (Initial mode)

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
  <!-- 
    completeness: FULL | PARTIAL | UNKNOWN
      FULL    = feature fully understood, all files mapped, behavior documented
      PARTIAL = core functionality identified but edge cases, config, or integrations unclear
      UNKNOWN = feature exists but not yet analyzed in detail
    
    test-coverage: TESTED | PARTIAL | NONE | UNKNOWN
      TESTED  = automated tests exist and cover core behavior
      PARTIAL = some tests exist but gaps identified
      NONE    = no automated tests found
      UNKNOWN = not yet assessed
  -->
  <completed-features>
    <feature id="CF1" completed="2026-02-08" completeness="FULL" test-coverage="TESTED">
      <title>Feature title</title>
      <description>What it does</description>
      <files>
        <file>path/to/relevant/file</file>
      </files>
      <test-files>
        <file>path/to/test/file</file>
      </test-files>
      <dependencies>
        <!-- other CF-IDs or external systems this feature depends on -->
        <depends-on>CF2, PostgreSQL</depends-on>
      </dependencies>
    </feature>

    <!-- Example: partially understood feature without tests -->
    <feature id="CF2" completed="2026-02-08" completeness="PARTIAL" test-coverage="NONE" 
             ref-item="42">
      <!-- ref-item points to a reference item in overview-features-bugs.xml -->
      <title>Payment processing</title>
      <description>Handles Stripe payments – checkout flow identified, webhook handling unclear</description>
      <files>
        <file>src/payments/checkout.py</file>
        <file>src/payments/webhooks.py</file>
      </files>
      <gaps>
        <gap>Webhook retry logic not understood</gap>
        <gap>Refund flow not mapped</gap>
      </gaps>
    </feature>
  </completed-features>
</project-overview>
```

Also generate `ai-docs/overview-features-bugs.xml` with any identified issues, improvements, or TODOs as items with `status="PENDING"`.

### Session Start

If `overview.xml` already exists, **read it** at the start of every session for project context. Do not re-run analysis unless the user explicitly triggers `/init_overview` or `/update`.

## Core Rules

### 1. Always Check Before Acting

Before implementing ANY user request (feature, bug, change, question about the codebase):

1. **Read** `ai-docs/overview.xml` (project context + existing features)
2. **Read** `ai-docs/overview-features-bugs.xml` (active items)
3. **Search** for existing items that match the request (by title, description, related files, or affected area)
4. **Impact check**: identify which existing features (from `<completed-features>`) could be affected by the requested change. If any affected feature has `completeness != FULL` or `test-coverage == NONE`:
   - **Warn the user** about the risk of breaking an incompletely mapped feature
   - **Check** if a `[REF]` item already exists for that feature – if not, create one as PENDING
   - **Recommend** completing the reference item before implementing the change
5. **Decide**:
   - **Existing item found** → update that item (status, tasks, details) rather than creating a duplicate
   - **No match** → create a new item with `status="PENDING"`
6. **Inform the user** which item ID was created or updated, and any impact warnings

### 2. Always Update the Plan

Every interaction that involves code changes, bug reports, or feature discussion **must** result in an update to `overview-features-bugs.xml`. This includes:

- New feature requests → new `<item type="feature" status="PENDING">`
- Bug reports → new `<item type="bug" status="PENDING">`
- Scope changes → update existing item's tasks, acceptance-criteria, or justification
- Implementation progress → update status (`PENDING` → `APPROVED` → `IN_PROGRESS` → `DONE`)
- Bugs found during implementation → new `<item type="bug">` with `depends-on` referencing the parent item
- Verification results → fill `<r>` block with outcome, observations, lessons-learned, files

### 3. Default Status is PENDING

All new items are created with `status="PENDING"`. The user must explicitly approve before implementation begins. Never skip to `APPROVED` or `IN_PROGRESS` without user confirmation.

**Exception – `!run` short-path:** When a creation command is invoked with the `!run` modifier (`/feature … !run`, `/bug … !run`, `/refactor … !run`, `/debt … !run`), the command invocation itself is the user's approval. After DA enrichment completes, auto-set `status="APPROVED"` and immediately execute the full `/run` lifecycle. Blocked on XL items and PROBLEM items.

Status lifecycle:
```
PENDING ──→ APPROVED ──→ PLANNED ──→ IN_PROGRESS ──→ REVIEW ──→ DONE ──→ ARCHIVED
   │                                                    │
   └──→ DENIED                               FAILED ──→ IN_PROGRESS
                                           (back to DEV, creates BUG item)
```

| Status | Meaning |
|---|---|
| `PENDING` | Created, awaiting user/PO approval |
| `APPROVED` | User confirmed; ready for DA to plan |
| `PLANNED` | DA attached implementation plan + security assessment |
| `IN_PROGRESS` | DEV actively working |
| `REVIEW` | Code complete, unit tests pass; TST verifying |
| `FAILED` | TST rejected; returns to IN_PROGRESS with linked BUG |
| `DONE` | All tests pass, acceptance criteria met |
| `DENIED` | Rejected at PENDING gate |
| `ARCHIVED` | Moved to archive; no active dependents |

The `PLANNED` and `REVIEW` states are optional for simple items. Simple bugs and small features may skip directly APPROVED → IN_PROGRESS → DONE when the implementation is straightforward.

### 4. Item Types

| Type | Default Priority | Created by command | Description |
|---|---|---|---|
| `feature` | MEDIUM | `/feature` | Deliverable capability |
| `bug` | HIGH | `/bug` | Defect; includes steps-to-reproduce |
| `refactoring` | MEDIUM | `/refactor` | Structural improvement without behavior change |
| `tech-debt` | LOW | `/debt` | Known technical compromise to address |
| `security-item` | HIGH | `/bug !security` | Security vulnerability or hardening task |
| `requirement` | MEDIUM | `/feature --requirement` | Raw user need; decomposed into epics/features |
| `epic` | MEDIUM | `/feature --epic` | XL grouping of features; has acceptance criteria, no tasks |
| `enabler` | MEDIUM | `/feature --enabler` | Technical prerequisite mapped to a feature |
| `problem` | HIGH | `/bug --problem` | Systemic or environmental issue (not a code bug) |

RELEASE, SPRINT, and BLOCKER items are managed via `/release`, `/sprint`, and `/blockers` commands respectively. They live in the same `overview-features-bugs.xml` file but follow a different structure (see `CLAUDE-roles-chapter.md`).

### 5. ID Assignment

- Read the current highest ID in `overview-features-bugs.xml`
- Assign the next sequential integer
- Sub-items use the parent ID as prefix for tasks: item 15 → tasks `15.1`, `15.2`, etc.

### 6. Complexity & Decomposition

Estimate complexity for every new item:
- **S** = isolated change, single file, < 1 day
- **M** = few files, clear scope, 1–3 days
- **L** = cross-cutting, multiple components, 3–7 days
- **XL** = epic-level → **must** be decomposed into sub-items with `parent="ID"`

If an item is XL: create the epic with `<acceptance-criteria>` and create sub-items with individual tasks. Do not put tasks directly on XL items.

### 7. Branch Naming Convention

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

### 8. Changelog

Update the `<changelog>` block in `overview-features-bugs.xml` **once per interaction** (not per item change). Group all changes from the same interaction into a single entry.

Format:
```xml
<changelog>
  <entry date="2026-02-08">Items 12, 14 created (PENDING). Item 3 → IN_PROGRESS.</entry>
  <entry date="2026-02-07">Item 10 → DONE, archived. Bug item 20 created from verification.</entry>
</changelog>
```

No entry for read-only interactions (Claude reads the plan but changes nothing).

### 9. Max Items per Interaction

Soft limit: **5 items** created or updated per response.

- **Create**: max 5 new items
- **Update**: max 5 existing items
- **Mixed**: max 5 total (creates + updates combined)
- **Overflow**: list remaining items as preview, ask user whether to continue
- **Exception**: initial project analysis (first-time plan creation) has no limit

### 10. Archival

Completed and denied items are moved **out of** `overview-features-bugs.xml` and **into** `ai-docs/overview-features-bugs-archive.xml`, while simultaneously being registered in `overview.xml`.

**When to archive:**
- `DONE` items: when the item AND all its sub-items are DONE, AND no active item has a `depends-on` referencing it
- `DENIED` items: immediately (no dependencies possible)

**Archival process:**

1. **Initialize** `overview-features-bugs-archive.xml` if it does not exist (see Files & Locations).

2. **Move** the item from the active section of `overview-features-bugs.xml` to `<archive>` in `overview-features-bugs-archive.xml`:
   ```xml
   <!-- In overview-features-bugs-archive.xml -->
   <archive>
     <item id="1" status="DONE" archived="2026-02-08" ...>
       <!-- full item preserved for history -->
     </item>
   </archive>
   ```

3. **Lessons extraction**: for DONE items with non-trivial `<r><lessons-learned>` content, extract and append to `ai-docs/lessons-learned.md` under the appropriate category (Technology, Architecture, Security, Testing, Process) with a sequential L-N ID. Skip trivially empty lessons.

4. **Add** a `<completed-features>` entry in `overview.xml` (for DONE items only):
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

5. **Changelog rotation**: after moving items, if `<changelog>` in `overview-features-bugs.xml` has more than 30 entries, move the oldest (beyond 30) to `<changelog-history>` in `overview-features-bugs-archive.xml`.

6. **Update** `<metadata><updated>` in `overview.xml` and both plan files.

7. **Update** architecture, dependencies, or security sections in `overview.xml` if the archived item introduced changes.

**Do not archive** items that are still referenced by active `depends-on`.

### 11. Security by Default

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

### 12. Security Updates on Archival

When archiving items that have `security="true"`, the `<security>` section in `overview.xml` **must** be updated:

- **DONE security items**: evaluate whether the mitigation resolved an existing concern or introduced a new security posture. Update or add `<concern>` entries accordingly.
- **DENIED security items**: if the denial leaves a known vulnerability unaddressed, add or keep the corresponding `<concern>` with a note that mitigation is outstanding.

The `<security>` section in `overview.xml` must always reflect the **current** security posture of the project – not just the initial analysis.

## XML Structure Quick Reference

```xml
<!-- Simple feature or bug (item-per-file: lives in ai-docs/items/NNNN.xml) -->
<item id="N" type="feature|bug|refactoring|tech-debt" status="PENDING" priority="CRITICAL|HIGH|MEDIUM|LOW" complexity="S|M|L|XL">
  <title>Short descriptive title</title>
  <branch>type/item-N-slug</branch>
  <justification>Why this is needed</justification>
  <depends-on>comma-separated item IDs or empty</depends-on>

  <!-- DA fills during enrichment — drives /run conflict-graph and TST regression scope -->
  <affected-files planned="true">
    <file role="modify">src/path/to/existing/file.py</file>   <!-- HARD conflict signal -->
    <file role="create">src/path/to/new/file.py</file>        <!-- no conflict possible -->
    <file role="delete">src/path/to/removed/file.py</file>    <!-- HARD conflict signal -->
    <file role="read">src/path/to/dependency.py</file>        <!-- no conflict -->
    <file role="create" test="true">tests/test_feature.py</file> <!-- soft conflict only -->
  </affected-files>

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

<!-- Index entry for the item above (lives in overview-features-bugs.xml) -->
<!-- planned-files = space-separated non-test modify/delete files from <affected-files> above -->
<item-ref id="N" type="feature" status="PENDING" priority="MEDIUM" complexity="M"
          title="Short descriptive title" branch="feature/item-N-slug"
          depends-on="" parent="" security=""
          planned-files="src/path/to/existing/file.py src/path/to/removed/file.py" />

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

<!-- Reference item for incomplete existing feature -->
<item id="N" type="refactoring" status="PENDING" priority="MEDIUM" complexity="M" ref-feature="CF2">
  <title>[REF] Feature name – complete mapping and add tests</title>
  <justification>Feature CF2 has completeness=PARTIAL, test-coverage=NONE</justification>
  <tasks>
    <task id="N.1">Map undocumented behavior</task>
    <task id="N.2">Write integration/unit tests for core paths</task>
  </tasks>
  ...
</item>
```

## Workflow Summary

```
First encounter (no overview.xml) or /init_overview
     │
     ▼
Full codebase scan → generate overview.xml + overview-features-bugs.xml
     │
     ▼
─────────────────────────────────────────────────────
     │
/update (XMLs already exist)
     │
     ▼
Full codebase scan → verify XMLs against code
     │
     ├─ Drift detected?  ──→ Update overview.xml
     ├─ New features?     ──→ Add to completed-features + create [REF] items
     ├─ Stale features?   ──→ Flag as STALE, warn user
     └─ Item warnings?    ──→ Report broken refs, stale items
     │
     ▼
─────────────────────────────────────────────────────
     │
Every subsequent request
     │
     ▼
Read overview.xml + overview-features-bugs.xml
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
                    ├──→ Move to <archive> in overview-features-bugs.xml
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
| `!run` | Short-path: auto-approve after enrichment and execute immediately; invoking the command with `!run` IS the approval | `/feature Add dark mode !run` |

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

### Lifecycle Transition Commands

| Command | Action | Transition |
|---|---|---|
| `/approve <ID> [ID...]` | Set status to APPROVED, generate branch name | PENDING → APPROVED |
| `/deny <ID> [reason]` | Set status to DENIED, archive immediately | PENDING → DENIED |
| `/plan-impl <ID>` | DA attaches implementation plan + security assessment | APPROVED → PLANNED |
| `/start <ID>` | SM assigns item to DEV, begins work | PLANNED → IN_PROGRESS |
| `/submit <ID>` | DEV submits for testing (unit tests must pass) | IN_PROGRESS → REVIEW |
| `/pass <ID>` | TST signs off; item is DONE | REVIEW → DONE |
| `/fail <ID> [reason]` | TST rejects; creates linked BUG item, returns to DEV | REVIEW → FAILED |

### Item Management Commands

| Command | Action |
|---|---|
| `/status <ID>` | Show current status, tasks, and dependencies of an item |
| `/list [filter]` | List items – filter by status, type, or priority |
| `/archive` | Archive all eligible DONE/DENIED items to archive file, extract lessons, rotate changelog, trigger full-test check |
| `/check-deps <ID>` | Show dependency tree and any blocking items |
| `/board` | Kanban-style view of all items grouped by status column |

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

1. **Read** `overview.xml` security section (known concerns) and all items with `security="true"` in `overview-features-bugs.xml`
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

### Release, Sprint, and Blocker Commands

| Command | Action |
|---|---|
| `/release <version> [--target <date>]` | Create RELEASE item; link features/bugs to scope; manage full gates (PO approval required) |
| `/sprint` | Show active sprint status |
| `/sprint create [ID...]` | Group 2–5 APPROVED items into a SPRINT (lightweight, no PO gates) |
| `/sprint close` | Close sprint when all scope items DONE; triggers full-test recommendation |
| `/blockers` | List active BLOCKER items |
| `/blockers <title> --blocks <ID,...>` | Create new BLOCKER item |
| `/blockers resolve <ID>` | Resolve a BLOCKER and unblock dependent items |
| `/translate <ID>` | Decompose a REQUIREMENT item into EPIC + FEATURE/ENABLER children |

### Knowledge Base Commands

| Command | Action |
|---|---|
| `/lessons` | Show all lessons learned, grouped by category |
| `/lessons <category>` | Filter lessons by category (`technologie`, `architektur`, `sicherheit`, `testing`, `prozess`) |

### Plan Overview Commands

| Command | Action |
|---|---|
| `/plan_summary` | Show summary: counts by status, type, priority + next actionable items |
| `/overview` | Show architecture summary from overview.xml |
| `/init_overview` | Run full code analysis in **initial** mode (creates both XML files, backs up existing) |
| `/update` | Run code analysis in **update** mode (verify + sync XMLs against current codebase) |

**Examples:**
```
/init_overview
→ Backs up existing XMLs (if any)
→ Full codebase scan...
→ Generated overview.xml: 3 patterns, 5 dependencies, 8 features (3 FULL, 4 PARTIAL, 1 UNKNOWN)
→ Generated overview-features-bugs.xml: 5 [REF] items, 2 bugs, 1 security concern (all PENDING)

/update
→ Verifying XMLs against codebase...
→ overview.xml: 2 changes (1 new dependency, 1 new security concern)
→ Features: 8 verified, 1 STALE, 1 NEW discovered
→ Items: 12 active, 2 warnings (1 stale PENDING, 1 broken depends-on)
→ Created 1 new [REF] item
```

### Command Processing Rules

1. **Always read both XML files first** – even for slash commands
2. **Still check for duplicates** – `/bug` must search before creating
3. **Still respect the 5-item limit** – `/approve 1 2 3 4 5 6 7` processes first 5, asks for confirmation
4. **Still update changelog** – every command that modifies the plan gets a changelog entry
5. **Confirm creation** – after processing, show: item ID, title, type, priority, status
6. **Unknown commands** – if a slash command is not recognized, list available commands

## Knowledge Base

Lessons learned are accumulated in `ai-docs/lessons-learned.md` during every `/archive` run.

**Format:** Markdown, organized by category: `Technology`, `Architecture`, `Security`, `Testing`, `Process`.

**Lesson entry:** `- **L-N** (YYYY-MM-DD, item-ID): Lesson text.`

**DA consults lessons before every `/plan-impl`**: reads `lessons-learned.md`, identifies relevant L-N entries, and references them in `<technical-parameters>` of the implementation plan. This prevents repeating past mistakes and propagates institutional knowledge.

**Only non-trivial lessons are recorded.** Skip empty, vague, or uninformative content ("no issues", "works as expected", etc.).

## Sprint Grouping and Full-Test Trigger

### SPRINT vs. RELEASE

| Aspect | SPRINT | RELEASE |
|---|---|---|
| Scope | 2–5 items | Any number |
| PO gates | None | scope-freeze + release-approval |
| Auto-created | Yes (by `/implement` with ≥ 2 APPROVED) | No (manual `/release`) |
| Full-test trigger | On close | On full-test-pass gate |

### Auto-Creation Rules (in `/implement`)

| APPROVED items | Action |
|---|---|
| 1 item | Start directly, no sprint |
| 2–5 items, no active sprint | Auto-create SPRINT, then proceed |
| > 5 items | Process first 5; suggest `/sprint create` or `/release` |

### Full-Test Counter

`overview-features-bugs.xml` metadata tracks two fields:

```xml
<metadata>
  ...
  <done-since-last-fulltest>0</done-since-last-fulltest>
  <last-fulltest-date></last-fulltest-date>
</metadata>
```

**Trigger conditions** (checked after every `/archive`):
- `done-since-last-fulltest` ≥ 5, OR
- `last-fulltest-date` is empty or older than 14 days, OR
- An active SPRINT was completed in this `/archive` run

When triggered, `/archive` outputs: *"N items archived since last full test (last: DATE). Recommendation: run `/full-test`."*

After a successful full-test run, reset the counter to 0 and update `last-fulltest-date`.

### 13. Resource Conflict Detection

To enable safe parallel execution, DA must identify which project source files each item will modify and flag conflicts with other active items.

**During every item enrichment** (creation commands and `/plan-impl`):

1. List all project source files the item will **modify** or **delete**.
2. Write `<affected-files planned="true">` in the item file, tagging each with `role` and `test="true"` for test files.
3. Cross-reference `planned-files` of all `APPROVED`/`IN_PROGRESS` items in the index.
4. For each **hard conflict** (same non-test source file):
   - Auto-set `depends-on={ID}` (lower ID runs first, unless priority warrants override).
   - Report: `"⚠ Resource conflict with item {ID}: {file}. depends-on set."`
5. For **test-file overlap**: warn only (soft — additive changes are usually merge-safe).
6. Write space-separated non-test modify/delete paths as `planned-files="{...}"` in the `<item-ref>` index entry.

**Dependency types:**

| Type | Cause | Enforced via |
|---|---|---|
| Logical | B needs A's output (e.g. A creates schema B reads) | `depends-on` — set by user or DA |
| Resource | A and B modify the same source file | `depends-on` — set automatically by DA |
| Soft | Same module/directory, no direct file overlap | Warning only — no `depends-on` |

**`/run` uses `planned-files` to build execution batches** — items without shared files run in parallel; items with overlapping `planned-files` (or explicit `depends-on`) are sequenced into separate batches.

---

## Important Reminders

- **Never implement without checking both XML files first**
- **Never create duplicate items** – always search existing items before adding
- **Never skip PENDING** – the user decides what gets built
- **Always check feature completeness** – warn if changes touch PARTIAL/UNKNOWN/NONE features
- **Always create `[REF]` items** for incomplete features that are at risk from active work
- **Always assess security impact** – every item gets a security check during risk evaluation
- **Always tag security items** – `security="true"` + `[SECURITY]` title prefix + `<security-impact>` block
- **Always populate `<affected-files>` during enrichment** – enables parallel execution and prevents silent overwrites
- **Always update `<r>` after implementation** – outcomes and lessons-learned are mandatory
- **Always archive to the correct location** – DONE items move to `ai-docs/items/archive/`; add to `completed-features` in `overview.xml`
- **Keep the XML valid** – malformed XML breaks the workflow
- **Respect the 5-item limit** – ask before processing more
- **Update changelog once per interaction** – grouped, not per item
- When in doubt about priority, complexity, or security impact, **ask the user**
