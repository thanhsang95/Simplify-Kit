#!/usr/bin/env bash
# A change that is finished and valid in every way except one: a scenario in
# its delta still carries the open-question marker.
#
# Everything else is deliberately clean, so there is exactly one reason to
# stop. Every task is ticked. The delta is ADDED only, under a requirement
# name the living spec does not already hold. Nothing is MODIFIED, so no
# merge can shrink anything, and no second unarchived change exists to
# contradict it. A run that stops for any of those reasons has invented a
# problem the fixture does not contain.
#
# The change also carries a resolved token alongside the open one: Q2's
# threshold was settled by looking up an existing convention and recorded
# under ## Assumptions, with no marker in the sentence. archive must block on
# Q1 and say nothing against Q2 — a recorded assumption is a decision, not an
# open question, and treating every entry under ## Assumptions as a blocker
# would make the marker meaningless.
#
# The consequence if this check is skipped: the marker merges into
# sk/specs/csv-export/spec.md, where it stops being a flagged gap and becomes
# a requirement like any other. archive is a one-way door — this is the check
# that keeps it shut.
set -eu

CHANGE=sk/changes/us-31200-csv-export
mkdir -p "$CHANGE/specs/csv-export" sk/specs/csv-export sk/changes/archive

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest

rules:
  ui:
    - A list operation over 5000 rows shows progress instead of blocking
EOF

cat > sk/specs/csv-export/spec.md <<'EOF'
# csv-export

### Requirement: Export respects the active filters

The CSV export SHALL contain exactly the rows visible under the filters and
search active when the export was requested.

#### Scenario: Filtered list exports the filtered rows

- **WHEN** an administrator exports the products list with filters applied
- **THEN** the file SHALL contain every filtered row and no others
EOF

cat > "$CHANGE/proposal.md" <<'EOF'
# 31200 — Make CSV export from the products list reliable

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/31200
**Type / State:** User Story / Active

## Summary

Exports fail silently on large catalogs and give no indication of progress.
Add automatic retry on failure and a progress indicator for long exports.

## Capabilities

**Added:** `csv-export` — retry on failure, progress indicator

## Assumptions

- Q2 — 5000 rows is the threshold for showing the progress indicator. Source:
  `sk/config.yaml`, which already sets 5000 rows as the point where a list
  operation shows progress instead of blocking. Verifiable: yes.

## Open questions

- Q1 — How many times should a failed export be retried before it gives up?
  The work item says "retries automatically before giving up" and never states
  a count; no existing convention covers it. Marker sits in the THEN of
  "Scenario: A failed export is retried before giving up" in
  `specs/csv-export/spec.md`.
EOF

cat > "$CHANGE/specs/csv-export/spec.md" <<'EOF'
## ADDED Requirements

### Requirement: Export recovers from transient failures

The CSV export SHALL retry a failed export automatically before reporting
failure to the administrator.

#### Scenario: A failed export is retried before giving up

- **WHEN** an export request fails
- **THEN** the export SHALL be retried [[OPEN:Q1]] times before the
  administrator is told it failed

#### Scenario: A retry that succeeds is not reported as a failure

- **WHEN** a retried export completes successfully
- **THEN** the administrator SHALL receive the file with no failure message

### Requirement: Long exports report progress

The CSV export SHALL show a progress indicator rather than blocking the UI
when the export is large enough to take noticeable time.

#### Scenario: A large export shows progress

- **WHEN** an administrator exports 5000 rows or more
- **THEN** a progress indicator SHALL be shown and the UI SHALL remain usable
EOF

cat > "$CHANGE/tasks.md" <<'EOF'
## 1. Retry

- [x] 1.1 Retry a failed export before surfacing the failure  (built on Q1)
- [x] 1.2 Suppress the failure message when a retry succeeds

## 2. Progress

- [x] 2.1 Show a progress indicator for exports of 5000 rows or more  (built on Q2)
EOF
