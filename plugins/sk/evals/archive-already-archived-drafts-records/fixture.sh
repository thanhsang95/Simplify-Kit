#!/usr/bin/env bash
# Three changes already archived (their spec is merged), for records mode.
#   us-10001-connector-auth     defines "Connector"; has a design.md that
#                               qualifies as an ADR
#   us-10002-connector-health   defines "Connector" the same way (duplicate) and
#                               "Profile" as a saved set of connector settings
#   us-10003-user-profiles      defines "Profile" as a user's display name and
#                               avatar (conflicts with the wording above)
# There is no sk/context.md and no sk/adr/ yet.
set -eu

A=sk/changes/archive
mkdir -p sk/specs/connector-auth $A/us-10001-connector-auth/specs/connector-auth $A/us-10002-connector-health $A/us-10003-user-profiles

cat > sk/config.yaml <<'CEOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
CEOF

cat > sk/specs/connector-auth/spec.md <<'CEOF'
# connector-auth

### Requirement: Connectors authenticate with stored credentials

The system SHALL authenticate a connector using credentials stored on the server.

#### Scenario: Connector signs in

- **WHEN** a connector is used
- **THEN** the server SHALL sign in with its stored credentials
CEOF

cat > $A/us-10001-connector-auth/proposal.md <<'CEOF'
# 10001 - Connectors authenticate server-side

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/10001
**Type / State:** User Story / Closed

## Summary

A **connector** is a configured link between the catalog portal and one external system. Connectors sign in to that system with credentials held on the server.
CEOF
cat > $A/us-10001-connector-auth/specs/connector-auth/spec.md <<'CEOF'
## ADDED Requirements

### Requirement: Connectors authenticate with stored credentials

The system SHALL authenticate a connector using credentials stored on the server.

#### Scenario: Connector signs in

- **WHEN** a connector is used
- **THEN** the server SHALL sign in with its stored credentials
CEOF
cat > $A/us-10001-connector-auth/design.md <<'CEOF'
# Design - us-10001-connector-auth

## Decision

Connector credentials are stored encrypted on the server and never sent to the browser; the browser only ever holds a connector id.

## Why

The external systems issue long-lived tokens with no scope limits, so a token leaked from a browser would grant full access. Keeping them server-side costs one extra hop per call.

## Alternatives considered

- **Short-lived tokens minted per session in the browser** - the external systems cannot issue them.
- **Encrypting tokens in browser storage** - the key would also live in the browser.

## Consequences

Every connector call goes through our server, so its availability bounds every integration, and moving to browser-held tokens later would mean re-issuing every credential.
CEOF
touch $A/us-10001-connector-auth/tasks.md

cat > $A/us-10002-connector-health/proposal.md <<'CEOF'
# 10002 - Show connector health

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/10002
**Type / State:** User Story / Closed

## Summary

A **connector** is a configured link between the catalog portal and one external system. Administrators see whether each connector is reachable. A **profile** is a saved set of connector settings that can be reused across connectors.
CEOF
cat > $A/us-10003-user-profiles/proposal.md <<'CEOF'
# 10003 - Let users edit their profile

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/10003
**Type / State:** User Story / Closed

## Summary

A **profile** is a user's display name and avatar, shown next to their changes.
CEOF
