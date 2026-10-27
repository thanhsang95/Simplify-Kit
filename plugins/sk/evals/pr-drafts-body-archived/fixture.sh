#!/usr/bin/env bash
# A change already archived: /sk:archive merged its delta into sk/specs/ and
# moved it under sk/changes/archive/, which is where it sits when people write
# the PR (the README says archive before push). The delta has one ADDED and
# one MODIFIED requirement, design.md has a contract, every task is ticked.
# Nothing here says any test was run. Product, org and work item ids are
# invented; no person, email or contract identifier appears here.
set -eu

C=sk/changes/archive/us-12345-field-selector
mkdir -p "$C/specs/field-selector" sk/specs/field-selector src

cat > sk/config.yaml <<'EOT'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Test: npm test
EOT

cat > "$C/proposal.md" <<'EOT'
# 12345 — Add product attributes to the field selector

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/12345
**Type / State:** User Story / Active
**AC source:** work item

## Summary

Administrators building transformation rules can pick system-defined product
attributes in the field selector, listed as their own group below standard
fields, and search covers both groups.

## Capabilities

**Added:** `field-selector` — attributes as a separate group
**Modified:** `field-selector` — search spans standard fields and attributes

## Assumptions

- Attribute group label is "Attributes" — confirmed
EOT

cat > "$C/specs/field-selector/spec.md" <<'EOT'
## ADDED Requirements

### Requirement: Field selector offers system attributes

The field selector SHALL offer system-defined product attributes in their own group below standard fields.

#### Scenario: Attributes listed as their own group

- **WHEN** an administrator opens the field selector
- **THEN** system-defined attributes SHALL be listed under the group label "Attributes", below "Standard fields"

#### Scenario: Each attribute shows name and key

- **WHEN** the attribute group is displayed
- **THEN** each entry SHALL show the attribute display name and its API field key

## MODIFIED Requirements

### Requirement: Field selector search

The field selector's search box SHALL filter every group it lists.

#### Scenario: Search filters standard fields

- **WHEN** an administrator types "title" into the search box
- **THEN** only standard fields whose name contains "title" SHALL remain

#### Scenario: Search filters attributes too

- **WHEN** an administrator types "brand" into the search box
- **THEN** the attribute "Brand" SHALL remain under "Attributes"
EOT

cat > "$C/design.md" <<'EOT'
# Design — us-12345-field-selector

## Contracts

    export function listSelectableFields(): Array<{ label: string; fields: SelectableField[] }>;

Serves: "Attributes listed as their own group", "Search filters attributes too".
EOT

cat > "$C/tasks.md" <<'EOT'
## 1. Attribute source

- [x] 1.1 Add `src/attribute-fields.ts` exporting `listAttributeFields()`
- [x] 1.2 Add `listSelectableFields()` to `src/field-selector.ts`

## 2. Search

- [x] 2.1 Make the search box filter the attribute group as well
EOT

cat > sk/specs/field-selector/spec.md <<'EOT'
# field-selector

### Requirement: Field selector offers system attributes

The field selector SHALL offer system-defined product attributes in their own group below standard fields.

#### Scenario: Attributes listed as their own group

- **WHEN** an administrator opens the field selector
- **THEN** system-defined attributes SHALL be listed under the group label "Attributes", below "Standard fields"

#### Scenario: Each attribute shows name and key

- **WHEN** the attribute group is displayed
- **THEN** each entry SHALL show the attribute display name and its API field key

### Requirement: Field selector search

The field selector's search box SHALL filter every group it lists.

#### Scenario: Search filters standard fields

- **WHEN** an administrator types "title" into the search box
- **THEN** only standard fields whose name contains "title" SHALL remain

#### Scenario: Search filters attributes too

- **WHEN** an administrator types "brand" into the search box
- **THEN** the attribute "Brand" SHALL remain under "Attributes"
EOT
