#!/usr/bin/env bash
# A change with one of each thing a PO/BA has to answer: a Gap (a criterion
# with no observable behaviour), an open question with its marker in the
# delta and a task built on it, and an unconfirmed assumption. Product, org
# and work item ids are invented; no person, email or contract identifier
# appears here.
set -eu

C=sk/changes/us-20900-account-lockout
mkdir -p "$C/specs/sign-in" sk/specs sk/changes/archive src

cat > sk/config.yaml <<'EOT'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Test: npm test
EOT

cat > "$C/proposal.md" <<'EOT'
# 20900 — Lock an account after repeated failed sign-ins

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/20900
**Type / State:** User Story / Active
**AC source:** work item

## Summary

After too many failed sign-in attempts the account is locked and the person
is told how to unlock it.

## Capabilities

**Added:** `sign-in` — account lockout

## Assumptions

- Failed attempts are counted per account, not per device — unconfirmed
- Q1 — 5 attempts used while building. Source: none yet. Verifiable: no.

## Open questions

- Q1 — How many failed attempts lock the account? (Scenario "Lock after repeated failures")

## Gaps

- AC 4 "Locking must be secure" — no observable behaviour stated; unclear what it asks for beyond the lock itself

## Design

Skipped — no public interface changes and no trade-off.
EOT

cat > "$C/specs/sign-in/spec.md" <<'EOT'
## ADDED Requirements

### Requirement: Repeated failed sign-ins lock the account

The sign-in page SHALL lock an account after repeated failed attempts.

#### Scenario: Lock after repeated failures

- **WHEN** a person enters a wrong password for the same account repeatedly
- **THEN** the account SHALL lock after [[OPEN:Q1]] failed attempts
EOT

cat > "$C/tasks.md" <<'EOT'
## 1. Lockout

- [x] 1.1 Count failed attempts per account  (built on Q1)
- [ ] 1.2 Show the locked-account message on the sign-in page
EOT
