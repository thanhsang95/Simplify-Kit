#!/usr/bin/env bash
# A finished change whose MODIFIED delta restates only the scenario it changed.
#
# The living spec holds three scenarios; the delta carries one. Because archive
# replaces a MODIFIED requirement wholesale, merging this as written would
# delete two scenarios — names still match, no conflict is raised, and the loss
# only surfaces when someone later asks what the requirement covers.
#
# archive is supposed to notice that the merged requirement would end up with
# fewer scenarios than the one it replaces, stop, and ask. Nothing may be
# written and nothing may be moved.
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

#### Scenario: Each attribute shows name and key

- **WHEN** the attribute group is displayed
- **THEN** each entry SHALL show the attribute display name and its API field key

#### Scenario: Publisher attributes are excluded

- **WHEN** an account has publisher-created custom attributes
- **THEN** those attributes SHALL NOT appear in the selector
EOF

cat > "$CHANGE/proposal.md" <<'EOF'
# 12345 — Group label wording

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/12345
**Type / State:** User Story / Active

## Summary

The attribute group label should read "Attributes" explicitly.

## Capabilities

**Modified:** `field-selector` — group label wording
EOF

cat > "$CHANGE/specs/field-selector/spec.md" <<'EOF'
## MODIFIED Requirements

### Requirement: Field selector offers system attributes

The field selector SHALL offer system-defined product attributes alongside
standard product fields.

#### Scenario: Attributes listed as their own group

- **WHEN** an administrator opens the field selector
- **THEN** system-defined attributes SHALL be listed under a group labelled "Attributes"
EOF

cat > "$CHANGE/tasks.md" <<'EOF'
## 1. Label

- [x] 1.1 Change the attribute group label to "Attributes"
EOF
