#!/usr/bin/env bash
# A finished change whose delta MODIFIES an existing requirement.
#
# The delta restates the requirement in full — both original scenarios plus the
# new one — which is what makes archive's replace semantics safe. The merged
# requirement must therefore end up with three scenarios, not one.
set -eu

CHANGE=sk/changes/us-12345-field-selector
mkdir -p "$CHANGE/specs/field-selector" sk/specs/field-selector sk/changes/archive

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
EOF

cat > sk/specs/field-selector/spec.md <<'EOF'
# field-selector

### Requirement: Field selector offers system attributes

The field selector SHALL offer system-defined product attributes alongside
standard product fields.

#### Scenario: Attributes listed as their own group

- **WHEN** an administrator opens the field selector
- **THEN** system-defined attributes SHALL be listed under their own group label
- **AND** standard fields SHALL remain listed separately

#### Scenario: Each attribute shows name and key

- **WHEN** the attribute group is displayed
- **THEN** each entry SHALL show the attribute display name and its API field key
EOF

cat > "$CHANGE/proposal.md" <<'EOF'
# 12345 — Search across both field groups

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/12345
**Type / State:** User Story / Active

## Summary

The field selector's search box currently filters standard fields only.
It should filter attributes at the same time.

## Capabilities

**Modified:** `field-selector` — search spans both groups
EOF

cat > "$CHANGE/specs/field-selector/spec.md" <<'EOF'
## MODIFIED Requirements

### Requirement: Field selector offers system attributes

The field selector SHALL offer system-defined product attributes alongside
standard product fields, and SHALL search both groups together.

#### Scenario: Attributes listed as their own group

- **WHEN** an administrator opens the field selector
- **THEN** system-defined attributes SHALL be listed under their own group label
- **AND** standard fields SHALL remain listed separately

#### Scenario: Each attribute shows name and key

- **WHEN** the attribute group is displayed
- **THEN** each entry SHALL show the attribute display name and its API field key

#### Scenario: Search spans both groups

- **WHEN** an administrator types a term into the field selector search box
- **THEN** both standard fields and attributes SHALL be filtered to matching entries
EOF

cat > "$CHANGE/tasks.md" <<'EOF'
## 1. Search

- [x] 1.1 Filter attributes alongside standard fields in the selector search
- [x] 1.2 Add vitest coverage for a term matching entries in both groups
EOF

cat > "$CHANGE/design.md" <<'DEOF'
# Design — us-12345-field-selector

## Decision

The selector's search runs in the browser over the full attribute list, loaded once when the selector opens, instead of calling the catalog API on each keystroke.

## Why

The partner catalog API contract caps us at 60 requests per minute per tenant, so per-keystroke search would exhaust it within seconds for a single administrator. Loading once costs one request per open and makes filtering instant.

## Alternatives considered

- **Debounced server-side search** — still spends the quota on every pause, and one typing burst can trip the cap.
- **Server-side search with a cache** — the API offers no cache validators, so entries would go stale with no way to detect it.

## Consequences

The whole attribute list must fit in one API response, and any future attribute source must also be loadable in a single call. A tenant with a very large attribute set would need this decision revisited.
DEOF
