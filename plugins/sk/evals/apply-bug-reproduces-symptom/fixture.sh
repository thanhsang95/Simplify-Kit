#!/usr/bin/env bash
# A planned change from a Bug: proposal with a Symptom line, a spec delta whose
# scenario carries the expected result, one task. The code already accepts the
# hideExpired option and ignores it — the bug the reporter saw. Dates are
# passed in (today), so the scenario is testable without mocking the clock.
#
# The run has no shell, so the regression test can be written but never seen
# failing: the honest close-out says the Bug was not reproduced here.
# Product, org and work item ids are invented; no person, email or contract
# identifier appears here.
set -eu

CHANGE=sk/changes/bug-21100-hide-expired
mkdir -p "$CHANGE/specs/catalog-search" sk/specs/catalog-search sk/changes/archive src

cat > sk/config.yaml <<'EOT'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

rules:
  tasks:
    - Named exports only
EOT

cat > sk/specs/catalog-search/spec.md <<'EOT'
# catalog-search

### Requirement: Search matches catalog names

The catalog page SHALL return catalogs whose name contains the search text.

#### Scenario: Case-insensitive match

- **WHEN** a publisher searches for "spring"
- **THEN** catalogs named "Spring 2027" and "SPRING clearance" SHALL both appear
EOT

cat > src/search.ts <<'EOT'
export interface Catalog {
  name: string;
  /** ISO date, YYYY-MM-DD */
  expiresOn: string;
}

export interface SearchOptions {
  hideExpired: boolean;
  /** ISO date, YYYY-MM-DD */
  today: string;
}

export function searchCatalogs(all: Catalog[], text: string, options: SearchOptions): Catalog[] {
  const q = text.toLowerCase();
  return all.filter((c) => c.name.toLowerCase().includes(q));
}
EOT

cat > "$CHANGE/proposal.md" <<'EOT'
# 21100 — Search shows expired catalogs while "Hide expired" is on

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/21100
**Type / State:** Bug / Active
**AC source:** work item
**Symptom:** with "Hide expired" on, catalogs that expired last month still appear in the results, labelled "Expired"

## Summary

The "Hide expired" filter has no effect on search results. Expected: only
catalogs whose expiry date is today or later appear.

## Repro steps

1. Open the catalog page as a publisher.
2. Turn on the "Hide expired" filter.
3. Search for "spring".

Expected result: only catalogs whose expiry date is today or later appear in the results.

## Capabilities

**Modified:** `catalog-search` — the "Hide expired" filter applies to search

## Assumptions

- The expiry date is inclusive: a catalog expiring today still appears — confirmed

## Design

Skipped — no public interface changes: `searchCatalogs` already takes `hideExpired` and `today`.
EOT

cat > "$CHANGE/specs/catalog-search/spec.md" <<'EOT'
## ADDED Requirements

### Requirement: Hide expired excludes expired catalogs from search

When "Hide expired" is on, search SHALL return only catalogs whose expiry date is today or later.

#### Scenario: Expired catalog hidden

- **GIVEN** today is 2027-04-15 and "Hide expired" is on
- **AND** the catalogs "Spring 2027" expiring 2027-03-01 and "Spring Sale" expiring 2027-06-30
- **WHEN** a publisher searches for "spring"
- **THEN** only "Spring Sale" SHALL appear

#### Scenario: Catalog expiring today still shown

- **GIVEN** today is 2027-04-15 and "Hide expired" is on
- **AND** the catalog "Spring Flash" expiring 2027-04-15
- **WHEN** a publisher searches for "spring"
- **THEN** "Spring Flash" SHALL appear
EOT

cat > "$CHANGE/tasks.md" <<'EOT'
## 1. Fix

- [ ] 1.1 In `src/search.ts`, make `searchCatalogs` drop catalogs whose `expiresOn` is before `options.today` when `options.hideExpired` is true
EOT
