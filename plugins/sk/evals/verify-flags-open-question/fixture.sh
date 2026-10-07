#!/usr/bin/env bash
# A change that is built, tested and fully ticked — except that the delta still
# carries [[OPEN:Q1]]: nobody has answered how many retries, so task 1.1 was
# built on the recorded working reading (3) and noted "(built on Q1)". The code
# is otherwise complete, so the only critical finding is that /sk:archive will
# stop on the marker. Verify has to say that, name Q1 and task 1.1, and leave
# the question open: answering it is a product decision, not a review finding.
set -eu

CHANGE=sk/changes/us-20001-csv-export-retry
mkdir -p "$CHANGE/specs/csv-export" sk/specs sk/changes/archive src test

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Test: npm test
  List operations of 5000 rows or more show progress instead of blocking.

rules:
  tasks:
    - Named exports only
EOF

cat > "$CHANGE/proposal.md" <<'EOF'
# 20001 — Retry failed CSV exports and show progress

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/20001
**Type / State:** User Story / Active
**AC source:** work item

## Summary

Add automatic retry on failure and a progress indicator for long exports.

## Capabilities

**Added:** `csv-export` — retry on failure, progress indicator

## Design

Skipped — no technical trade-off; both behaviours wrap the existing export call.

## Assumptions

- Q1 — Working reading until the product owner answers: 3 retries. Source:
  none, chosen so the retry loop could be built. Unconfirmed.
- Q2 — 5000 rows is the threshold for showing the progress indicator. Source:
  `sk/config.yaml`. Verifiable: yes.

## Open questions

- Q1 — How many times should a failed export be retried before it gives up?
  The work item says "retries automatically before giving up" and never states
  a count. Marker sits in the THEN of "Scenario: A failed export is retried
  before giving up" in `specs/csv-export/spec.md`.
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
- [x] 2.2 Tests covering the scenarios this change added
EOF

cat > src/csv-export.ts <<'EOF'
export const MAX_RETRIES = 3;
export const PROGRESS_THRESHOLD_ROWS = 5000;

export interface ExportResult {
  file?: Blob;
  failureMessage?: string;
}

export async function exportCsv(run: () => Promise<Blob>): Promise<ExportResult> {
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      return { file: await run() };
    } catch {
      // retry
    }
  }
  return { failureMessage: 'Export failed' };
}

export function showsProgress(rowCount: number): boolean {
  return rowCount >= PROGRESS_THRESHOLD_ROWS;
}
EOF

cat > test/csv-export.test.ts <<'EOF'
import { describe, expect, it, vi } from 'vitest';
import { exportCsv, MAX_RETRIES, showsProgress } from '../src/csv-export';

describe('exportCsv', () => {
  it('gives up after MAX_RETRIES retries', async () => {
    const run = vi.fn().mockRejectedValue(new Error('boom'));
    const result = await exportCsv(run);
    expect(run).toHaveBeenCalledTimes(MAX_RETRIES + 1);
    expect(result.failureMessage).toBe('Export failed');
  });

  it('reports no failure when a retry succeeds', async () => {
    const run = vi.fn().mockRejectedValueOnce(new Error('boom')).mockResolvedValue(new Blob(['a']));
    const result = await exportCsv(run);
    expect(result.failureMessage).toBeUndefined();
    expect(result.file).toBeDefined();
  });
});

describe('showsProgress', () => {
  it('shows progress from 5000 rows', () => {
    expect(showsProgress(4999)).toBe(false);
    expect(showsProgress(5000)).toBe(true);
  });
});
EOF
