#!/usr/bin/env bash
# A workspace as SimplifyKit 0.1.x left it:
#   - .gitignore has no sk/changes/archive/ line
#   - open change A: written in one go, tasks.md present, no design.md and no
#     "## Design" section (item 2), no "**AC source:**" line
#   - open change B: stopped at Gaps because the acceptance criteria were
#     missing, so no spec delta and no "**AC source:**" line (item 3)
#   - an archived change with a design.md (item 5, report only)
#   - CLAUDE.md section written by the old init, no mention of /sk:continue
#   - config.yaml carries a sentinel comment: a rewrite of it loses the comment
set -eu

mkdir -p sk/specs/field-selector sk/changes/archive/us-10000-old-change \
  sk/changes/us-12345-field-selector/specs/field-selector \
  sk/changes/us-20600-catalog-download

cat > sk/config.yaml <<'CEOF'
# KEEP-ME: hand-written note that a regenerated config would lose
context: |
  Stack: TypeScript 5.6, Node 20, vitest
rules:
  specs:
    - Describe observable behaviour, not internal mechanism
CEOF

touch sk/specs/.gitkeep sk/changes/.gitkeep sk/changes/archive/.gitkeep

cat > sk/specs/field-selector/spec.md <<'CEOF'
# field-selector

### Requirement: Field selector offers standard fields

The field selector SHALL offer the standard product fields.

#### Scenario: Standard fields listed

- **WHEN** an administrator opens the field selector
- **THEN** the standard product fields SHALL be listed
CEOF

cat > .gitignore <<'CEOF'
node_modules/
dist/
CEOF

cat > CLAUDE.md <<'CEOF'
# Project notes

Build with `npm run build`.

## SimplifyKit

`sk/` holds specs (`sk/specs/`) and planned changes (`sk/changes/`).

- `/sk:init` — set up the workspace
- `/sk:propose AB#<id>` — plan a change from a work item
- `/sk:apply <id>` — implement its tasks
- `/sk:archive <id>` — merge its spec into `sk/specs/`
CEOF

CHANGE=sk/changes/us-12345-field-selector
cat > "$CHANGE/proposal.md" <<'CEOF'
# 12345 — Add product attributes to the field selector

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/12345
**Type / State:** User Story / Active

## Summary

Administrators need system-defined attributes in the field selector.

## Capabilities

**Modified:** `field-selector` — attributes alongside standard fields

## Assumptions

## Open questions

## Gaps

## Impact

- `src/field-selector.ts` — new group
CEOF
cat > "$CHANGE/specs/field-selector/spec.md" <<'CEOF'
## ADDED Requirements

### Requirement: Field selector offers system attributes

The field selector SHALL offer system-defined product attributes alongside standard fields.

#### Scenario: Attributes listed as their own group

- **WHEN** an administrator opens the field selector
- **THEN** system-defined attributes SHALL be listed under their own group label
CEOF
cat > "$CHANGE/tasks.md" <<'CEOF'
## 1. Attribute source

- [ ] 1.1 Add the attribute group to the selector
CEOF

cat > sk/changes/us-20600-catalog-download/proposal.md <<'CEOF'
# 20600 — Faster catalog downloads

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/20600
**Type / State:** User Story / New

## Summary

Downloads feel slow for large catalogs.

## Gaps

- The work item has no acceptance criteria; asked the user for them.
CEOF

cat > sk/changes/archive/us-10000-old-change/proposal.md <<'CEOF'
# 10000 — Old change

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/10000
**Type / State:** User Story / Closed
CEOF
cat > sk/changes/archive/us-10000-old-change/design.md <<'CEOF'
# Design — us-10000-old-change

## Decision

Exports are generated server-side and streamed, not built in the browser.

## Why

Catalogs can exceed a million rows; the browser cannot hold them.
CEOF
