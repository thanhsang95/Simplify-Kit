#!/usr/bin/env bash
# A planned change, fully specified, with every task still open.
#
# Task 1.1 requires a NEW file outside sk/ — that is deliberate: file_exists
# only sees files created during the run, and the write-path grader needs a
# legitimate write outside sk/ to prove its pattern matches anything at all.
set -eu

CHANGE=sk/changes/us-12345-field-selector
mkdir -p "$CHANGE/specs/field-selector" sk/specs sk/changes/archive src

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

rules:
  tasks:
    - Named exports only
EOF

cat > src/field-selector.ts <<'EOF'
export interface SelectableField {
  key: string;
  label: string;
}

export function listStandardFields(): SelectableField[] {
  return [
    { key: 'product_title', label: 'Product Title' },
    { key: 'product_description', label: 'Product Description' },
  ];
}
EOF

cat > "$CHANGE/proposal.md" <<'EOF'
# 12345 — Add product attributes to the field selector

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/12345
**Type / State:** User Story / Active

## Summary

The field selector currently offers standard product fields only. Administrators
also need system-defined attributes, listed as their own group.

## Capabilities

**Modified:** `field-selector` — attributes alongside standard fields
EOF

cat > "$CHANGE/specs/field-selector/spec.md" <<'EOF'
## ADDED Requirements

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

cat > "$CHANGE/tasks.md" <<'EOF'
## 1. Attribute source

- [ ] 1.1 Add `src/attribute-fields.ts` exporting `listAttributeFields()`, returning system-defined attributes with `key` and `label`
- [ ] 1.2 Extend `listStandardFields` usage in `src/field-selector.ts` with a `listSelectableFields()` export that returns standard fields and attributes as two labelled groups
EOF
