---
description: 'Run a security audit or show security status for the codebase.'
name: 'Security audit'
argument-hint: 'Optional area (auth, api, status, etc.).'
agent: 'agent'
---
<!-- GENERATED FILE — do not edit directly.
     Source:   .claude/commands/security.md
     Metadata: scripts/copilot-headers.json
     Regenerate: python3 scripts/generate-copilot-prompts.py -->

Run a **security audit** of the codebase.

**Arguments:** `$ARGUMENTS` (optional: specific area like "auth", "api", or "status")

## Modes

### `/security` (no arguments) – Full audit
1. **Read** `ai-docs/overview.xml` (`<security>` section) and all items with `security="true"` in `overview-features-bugs.xml` in parallel.
2. **Scan the codebase** against all 7 security categories:
   - **AUTH**: Authentication, authorization, session management, token handling
   - **INPUT**: Injection (SQL, XSS, command), validation, sanitization
   - **DATA**: Storage encryption, PII handling, data leakage, backup security
   - **NETWORK**: TLS, CORS, CSP, SSRF, API security, rate limiting
   - **CRYPTO**: Key management, hashing, signing, random number generation
   - **ACCESS**: File permissions, path traversal, privilege escalation
   - **DISCLOSURE**: Error messages, stack traces, debug endpoints, version exposure
3. **Cross-reference** with existing security items (by title + file) to avoid duplicates.
4. **Create bug items** for each new finding:
   - `type="bug"`, `security="true"`, `status="PENDING"`
   - Title prefixed with `[SECURITY]`
   - `priority="HIGH"` minimum, `CRITICAL` if exploitable without auth or affects data integrity
   - Full `<security-impact>` block with `<category>`, `<threat>`, `<mitigation>`
5. **Update** the `<security>` section in `overview.xml` with new `<concern>` entries.
6. **Update `<changelog>`**.
7. **Report** your findings using this structure:

```xml
<security-report date="YYYY-MM-DD">
  <summary>N findings across X categories. N new items created, N already tracked.</summary>
  <findings>
    <finding category="AUTH|INPUT|DATA|NETWORK|CRYPTO|ACCESS|DISCLOSURE"
             severity="CRITICAL|HIGH|MEDIUM" item-id="N">
      Short description + file reference
    </finding>
  </findings>
  <coverage>
    <category name="AUTH" status="AUDITED|CLEAN|SKIPPED" />
    <!-- repeat for all 7 -->
  </coverage>
</security-report>
```

### `/security <area>` – Focused audit
Same process limited to the specified area (e.g., "auth" → AUTH category, "api" → INPUT + NETWORK).

### `/security status` – Security posture overview
1. Read the `<security>` section of `overview.xml` and all `security="true"` items from `overview-features-bugs.xml`.
2. Report:
   - Open `<concern>` entries in `overview.xml`
   - Security items by status (PENDING, IN_PROGRESS, DONE)
   - Uncovered categories (no items or last audit > 30 days ago)

## Important

- Respect the 5-item-per-interaction limit for new findings
- Security bugs default to `priority="HIGH"` minimum
- Always cross-reference to avoid duplicates
- Keep XML valid
