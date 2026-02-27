# Project Agents and Orchestration

This document combines the role/skill mapping from `AGENTS.md` with the orchestration model from `AGENT.md`.

## Overview

Five specialized agents form the workflow. The main instance acts as the **Orchestrator**: it reads the XML plan, routes commands, coordinates handoffs, and reports results.

| Agent file | Role | Domain |
|---|---|---|
| `.claude/agents/po.md` | Product Owner (PO) | Business value, requirements, approval gates |
| `.claude/agents/sm.md` | Scrum Master (SM) | Process, flow, blockers, releases, archival |
| `.claude/agents/da.md` | DevSecOps Architect (DA) | Technical design, security, architecture |
| `.claude/agents/dev.md` | Developer (DEV) | Implementation, unit tests |
| `.claude/agents/tst.md` | Tester (TST) | Verification, quality gates, bug creation |

## Roles, skills, and typical tasks

## Orchestrator
Purpose: Controls routing, context preparation, handoffs, and result synthesis across all roles.
Uses skills:
- chordpro-project-orientation
- chordpro-plan-xml-lifecycle
- chordpro-testing-and-ci
- chordpro-archive-and-lessons
Typical tasks:
- Slash-command routing to PO/DA/SM/DEV/TST
- Consolidated status and progress reporting
- Ensuring plan and overview documents remain consistent

## Product Owner (PO)
Purpose: Translates requirements into backlog-ready items, prioritizes, and owns approval gates.
Uses skills:
- chordpro-project-orientation
- chordpro-plan-xml-lifecycle
Typical tasks:
- Structuring new feature/bug/debt items
- Managing PENDING → APPROVED or DENIED transitions
- Clarifying acceptance criteria and scope

## DevSecOps Architect (DA)
Purpose: Defines technical implementation, architecture constraints, security aspects, and plannability.
Uses skills:
- chordpro-project-orientation
- chordpro-plan-xml-lifecycle
- chordpro-delegate-integration
- chordpro-html5-rendering-playbook
- chordpro-archive-and-lessons
Typical tasks:
- Creating `/plan-impl` and technical task structures
- Assessing and documenting security impacts
- Updating architecture/feature drift in `overview.xml` and plan XML

## Scrum Master (SM)
Purpose: Owns workflow governance, status flow, sprint/release coordination, and archive runs.
Uses skills:
- chordpro-project-orientation
- chordpro-plan-xml-lifecycle
- chordpro-archive-and-lessons
- chordpro-testing-and-ci
Typical tasks:
- Coordinating PLANNED → IN_PROGRESS transitions
- Managing blockers and dependencies
- Running archive tasks including changelog rotation and full-test recommendation

## Developer (DEV)
Purpose: Implements code changes, adds tests, and hands over verifiable work in REVIEW.
Uses skills:
- chordpro-project-orientation
- chordpro-perl-backend-implementation
- chordpro-html5-rendering-playbook
- chordpro-delegate-integration
- chordpro-testing-and-ci
Typical tasks:
- Implementing parser/backend/template changes
- Adding regression-safe tests
- Documenting outcomes in a plan-compliant format

## Tester (TST)
Purpose: Verifies implementations against acceptance criteria and protects against regressions.
Uses skills:
- chordpro-project-orientation
- chordpro-testing-and-ci
- chordpro-html5-rendering-playbook
- chordpro-delegate-integration
Typical tasks:
- Running focused and integration test passes with `prove`/`make test`
- Making PASS/FAIL decisions with reproducible evidence
- Creating clean bug reproductions and feeding back into the plan

## Invocation Model

### Command routing

When a slash command is received, route it to the responsible agent:

| Command | Agent |
|---|---|
| `/feature`, `/approve`, `/deny` | `po` |
| `/start`, `/archive`, `/release`, `/blockers`, `/sprint` | `sm` |
| `/plan-impl`, `/security`, `/init_overview`, `/update`, `/translate`, `/refactor`, `/debt`, `/lessons` | `da` |
| `/submit` + implementation work | `dev` |
| `/pass`, `/fail` | `tst` |
| `/status`, `/list`, `/board`, `/check-deps`, `/plan_summary`, `/overview` | Orchestrator (without delegation) |

### Explicit delegation

Users or the orchestrator can explicitly invoke roles for specialized tasks.

### Orchestrator responsibilities

The main instance:
- reads and maintains `ai-docs/overview.xml` and `ai-docs/overview-features-bugs.xml` (active items); loads `ai-docs/overview-features-bugs-archive.xml` only when needed
- routes slash commands to the correct agent
- handles read-only queries directly (`/status`, `/list`, `/board`)
- coordinates handoffs at lifecycle gates
- reports status and results to the user
- enforces the 5-items-per-interaction limit
- writes changelog entries when no delegation occurs

## Lifecycle and handoffs

Workflow with role ownership at each gate:

```text
USER          PO              DA              SM            DEV           TST
 │             │               │               │              │             │
 ├─ /feature ─►│               │               │              │             │
 │             ├─ creates item │               │              │             │
 │             │   [PENDING]   │               │              │             │
 │◄── review ─┤               │               │              │             │
 ├─ /approve ─►│               │               │              │             │
 │             │   [APPROVED]  │               │              │             │
 │             │               ├─ /plan-impl   │              │             │
 │             │               │   [PLANNED]   │              │             │
 │             │               │               ├─ /start ────►│             │
 │             │               │               │   [IN_PROG]  ├─ build      │
 │             │               │               │              ├─ /submit ──►│
 │             │               │               │              │  [REVIEW]   ├─ verify
 │             │               │               │              │     PASS ──►├─ [DONE]
 │             │               │               │◄── /archive ─┴─────────────┘
 │             │               │               │         FAIL ─► [FAILED]
 │             │               │               │                  + new BUG
```

### Workflow-log protocol

Each agent adds a `<workflow-log>` entry for gate transitions:

```xml
<workflow-log>
	<entry timestamp="2026-02-21" role="PO"  action="approved"  from-status="PENDING"     to-status="APPROVED" />
	<entry timestamp="2026-02-22" role="DA"  action="planned"   from-status="APPROVED"    to-status="PLANNED" />
	<entry timestamp="2026-02-23" role="SM"  action="started"   from-status="PLANNED"     to-status="IN_PROGRESS" />
	<entry timestamp="2026-02-24" role="DEV" action="submitted" from-status="IN_PROGRESS" to-status="REVIEW" />
	<entry timestamp="2026-02-24" role="TST" action="passed"    from-status="REVIEW"      to-status="DONE" />
</workflow-log>
```

## Delegate vs. handle inline

| Situation | Approach |
|---|---|
| `/status`, `/list`, `/board`, `/plan_summary`, `/overview` | Orchestrator handles directly |
| Create a simple item with clear scope | Orchestrator handles directly |
| `/approve`, `/deny` | Delegate to `po` |
| `/plan-impl` (implementation planning) | Delegate to `da` |
| `/start` (sprint assignment) | Delegate to `sm` |
| `/archive` (archival + XML sync) | Delegate to `sm` |
| `/submit` + full implementation | Delegate to `dev` |
| `/pass` or `/fail` (verification) | Delegate to `tst` |
| `/security` (full or focused) | Delegate to `da` |
| `/init_overview` or `/update` | Delegate to `da` |
| `/release` or `/blockers` | Delegate to `sm` |
| Complex backlog grooming or scope negotiation | Delegate to `po` |
| Release tests | Delegate to `tst` |

## Agent Tool Permissions

| Agent | Tools |
|---|---|
| `po` | Read, Write, Edit, Glob, Grep |
| `sm` | Read, Write, Edit, Glob, Grep |
| `da` | Read, Write, Edit, Glob, Grep, Bash |
| `dev` | Read, Write, Edit, Glob, Grep, Bash |
| `tst` | Read, Write, Edit, Glob, Grep, Bash |

DA, DEV, and TST have Bash access for code scans, tests, and build tools. PO and SM only need read/write access for XML plan maintenance.

## Installing agents in the project

The agent files under `template/.claude/agents/` are installed into the target project’s `.claude/agents/` directory via `setup.sh`. After installation, Claude Code detects them automatically and they can be referenced in slash commands.
