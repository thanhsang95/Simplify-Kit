#!/usr/bin/env bash
# An open change with its delta and design.md written and no tasks.md yet, so
# /sk:pr picks spec review. proposal.md carries ## Risk (preliminary) at
# Medium, two-way, touching src/Auth/** (listed under `sensitive:`). The draft
# PR body must carry that rating over and say it is an estimate made before
# any code exists. Product, org and work item ids are invented; no person,
# email or contract identifier appears here.
set -eu

C=sk/changes/us-21700-idle-timeout
mkdir -p "$C/specs/sign-in" sk/specs sk/changes/archive src/Auth

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Test: npm test

sensitive:
  - src/Auth/**

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
EOF

cat > src/Auth/session.ts <<'EOF'
export interface Session { id: string; accountId: string; lastSeenOn: string }

export function endSession(sessionId: string): void {
  // removes the session from the session store
}
EOF

cat > "$C/proposal.md" <<'EOF'
# 21700 — Sign out after 30 minutes without activity

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/21700
**Type / State:** User Story / Active
**AC source:** work item

## Summary

A session with no activity for 30 minutes is signed out, and the person is
told why on the sign-in page.

## Capabilities

**Added:** `sign-in` — idle timeout

## Assumptions

- Activity means any request the signed-in page makes, including background refreshes — unconfirmed

## Open questions

## Gaps

## Impact

- `src/Auth/session.ts` — new idle check on each request

## Risk (preliminary)

**Level:** Medium — unconfirmed
**Door:** two-way — only adds a check; reverting the commit restores sessions that never time out
**Sensitive areas:** src/Auth/**
**Early review:** yes
EOF

cat > "$C/specs/sign-in/spec.md" <<'EOF'
## ADDED Requirements

### Requirement: An idle session is signed out

The portal SHALL sign out a session that has made no request for 30 minutes.

#### Scenario: Idle for 30 minutes

- **WHEN** a signed-in session makes no request for 30 minutes and then makes one
- **THEN** the person SHALL be sent to the sign-in page with the message "You were signed out after 30 minutes without activity."

#### Scenario: Active session stays signed in

- **WHEN** a signed-in session makes a request every 10 minutes
- **THEN** the session SHALL stay signed in
EOF

cat > "$C/design.md" <<'EOF'
# Design — us-21700-idle-timeout

## Contracts

### `isIdle` — src/Auth/session.ts

```ts
export const IDLE_LIMIT_MINUTES = 30;
export function isIdle(session: Session, now: Date): boolean;
```

- **Serves:** Idle for 30 minutes; Active session stays signed in
- **Errors:** none
- **Changes:** new
EOF
