#!/usr/bin/env bash
# The same change as verify-reports-missing-requirement, but finished for real:
# both requirements are in the code and every scenario has a test. Nothing here
# should be reported as critical. This case exists because a verify that always
# answers "not ready" would pass the missing-requirement case; a reviewer whose
# alarms are false gets ignored, so the clean path is measured too.
set -eu

CHANGE=sk/changes/us-12345-field-selector
mkdir -p "$CHANGE/specs/field-selector" sk/specs sk/changes/archive src test

cat > sk/config.yaml <<'EOF2'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

rules:
  tasks:
    - Named exports only
EOF2

cat > src/field-selector.ts <<'EOF2'
import { listAttributeFields } from './attribute-fields';

export interface SelectableField {
  key: string;
  label: string;
}

export interface FieldGroup {
  label: string;
  fields: SelectableField[];
}

export function listStandardFields(): SelectableField[] {
  return [
    { key: 'product_title', label: 'Product Title' },
    { key: 'product_description', label: 'Product Description' },
  ];
}

export function listSelectableFields(): FieldGroup[] {
  return [
    { label: 'Standard fields', fields: listStandardFields() },
    { label: 'Attributes', fields: listAttributeFields() },
  ];
}

export const NO_MATCHING_FIELDS = 'No matching fields';

export function searchFields(query: string): SelectableField[] | typeof NO_MATCHING_FIELDS {
  const needle = query.toLowerCase();
  const matches = listSelectableFields()
    .flatMap((group) => group.fields)
    .filter((f) => f.label.toLowerCase().includes(needle) || f.key.toLowerCase().includes(needle));
  return matches.length > 0 ? matches : NO_MATCHING_FIELDS;
}
EOF2

cat > src/attribute-fields.ts <<'EOF2'
import type { SelectableField } from './field-selector';

export function listAttributeFields(): SelectableField[] {
  return [
    { key: 'brand', label: 'Brand' },
    { key: 'sku', label: 'SKU' },
    { key: 'weight_kg', label: 'Weight (kg)' },
  ];
}
EOF2

cat > test/field-selector.test.ts <<'EOF2'
import { describe, expect, it } from 'vitest';
import { listSelectableFields, searchFields } from '../src/field-selector';

describe('listSelectableFields', () => {
  it('lists attributes as their own group after standard fields', () => {
    const groups = listSelectableFields();
    expect(groups.map((g) => g.label)).toEqual(['Standard fields', 'Attributes']);
    expect(groups[1].fields.map((f) => f.key)).toEqual(['brand', 'sku', 'weight_kg']);
  });
});

describe('searchFields', () => {
  it('matches label or key, ignoring case', () => {
    expect(searchFields('WEIGHT')).toEqual([{ key: 'weight_kg', label: 'Weight (kg)' }]);
  });

  it('reports no match', () => {
    expect(searchFields('zzz')).toBe('No matching fields');
  });
});
EOF2

cat > "$CHANGE/proposal.md" <<'EOF2'
# 12345 — Add product attributes to the field selector

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/12345
**Type / State:** User Story / Active
**AC source:** work item

## Summary

The field selector currently offers standard product fields only. Administrators
also need system-defined attributes, listed as their own group, and a search
box that finds a field by its label or key.

## Capabilities

**Modified:** `field-selector` — attributes alongside standard fields, and search

## Design

Skipped — no technical trade-off; both changes extend the existing module.
EOF2

cat > "$CHANGE/specs/field-selector/spec.md" <<'EOF2'
## ADDED Requirements

### Requirement: Field selector offers system attributes

The field selector SHALL offer system-defined product attributes alongside
standard product fields.

#### Scenario: Attributes listed as their own group

- **WHEN** an administrator opens the field selector
- **THEN** system-defined attributes SHALL be listed under their own group label
- **AND** standard fields SHALL remain listed separately

### Requirement: Field selector search

The field selector SHALL let an administrator find a field by typing part of
its label or its key.

#### Scenario: Search matches label or key, case-insensitively

- **WHEN** an administrator types `WEIGHT` into the field selector search
- **THEN** only fields whose label or key contains `weight`, ignoring case, SHALL be listed

#### Scenario: No match

- **WHEN** the search text matches no field
- **THEN** the field selector SHALL show "No matching fields"
EOF2

cat > "$CHANGE/tasks.md" <<'EOF2'
## 1. Attribute source

- [x] 1.1 Add `src/attribute-fields.ts` exporting `listAttributeFields()`, returning exactly these system-defined attributes as `{ key, label }`: `brand` / "Brand", `sku` / "SKU", `weight_kg` / "Weight (kg)"
- [x] 1.2 Add a `listSelectableFields()` export to `src/field-selector.ts` that returns two groups, `{ label: 'Standard fields', fields }` then `{ label: 'Attributes', fields }`

## 2. Search

- [x] 2.1 Add a `searchFields(query)` export to `src/field-selector.ts` that filters every selectable field by label or key, case-insensitively, and returns the "No matching fields" message when nothing matches
- [x] 2.2 Tests covering the scenarios this change added
EOF2
