#!/usr/bin/env bash
# An open change whose planning is finished — proposal, delta, design.md and
# tasks.md — but whose tasks are all unticked: nothing is built yet. /sk:pr
# must pick spec review and draft a body for a draft PR that carries only the
# spec, without the code-review sections. Product, org and work item ids are
# invented; no person, email or contract identifier appears here.
set -eu

C=sk/changes/us-21600-saved-searches
mkdir -p "$C/specs/catalog-search" sk/specs sk/changes/archive src

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Test: npm test

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
EOF

cat > src/catalog-search.ts <<'EOF'
export interface SearchQuery { text: string; category?: string }

export function searchCatalog(query: SearchQuery): string[] {
  return [];
}
EOF

cat > "$C/proposal.md" <<'EOF'
# 21600 — Save a catalog search

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/21600
**Type / State:** User Story / Active
**AC source:** work item

## Summary

A publisher can save a catalog search under a name and run it again later
from a "Saved searches" list.

## Capabilities

**Added:** `catalog-search` — saved searches

## Assumptions

- A saved search keeps the text and the category filter, nothing else — unconfirmed

## Open questions

## Gaps

## Impact

- `src/catalog-search.ts` — new saved-search functions
EOF

cat > "$C/specs/catalog-search/spec.md" <<'EOF'
## ADDED Requirements

### Requirement: A catalog search can be saved and run again

The catalog page SHALL let a publisher save the current search under a name
and run it again from a "Saved searches" list.

#### Scenario: Save the current search

- **WHEN** a publisher searches for "lamp" in category "Lighting" and saves it as "Lamps"
- **THEN** "Lamps" SHALL appear in the "Saved searches" list

#### Scenario: Run a saved search

- **WHEN** a publisher picks "Lamps" from the "Saved searches" list
- **THEN** the catalog SHALL show the results of searching "lamp" in category "Lighting"
EOF

cat > "$C/design.md" <<'EOF'
# Design — us-21600-saved-searches

## Contracts

### `saveSearch` — src/catalog-search.ts

```ts
export interface SavedSearch { name: string; query: SearchQuery }
export function saveSearch(publisherId: string, name: string, query: SearchQuery): SavedSearch;
export function listSavedSearches(publisherId: string): SavedSearch[];
```

- **Serves:** Save the current search; Run a saved search
- **Errors:** none
- **Changes:** new
EOF

cat > "$C/tasks.md" <<'EOF'
## 1. Saved searches

- [ ] 1.1 Add `saveSearch` and `listSavedSearches` to `src/catalog-search.ts`
- [ ] 1.2 Show the "Saved searches" list on the catalog page and run the picked search
EOF
