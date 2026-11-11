#!/usr/bin/env bash
# A change that does everything its spec asks: one requirement, two scenarios,
# both implemented and tested, every task ticked. But toBatches stops its loop
# at `orders.length - 1` (src/order-batches.ts:7), so whenever the count is one
# more than a multiple of 50 — 1, 51, 101 orders — the last order is never put
# in a batch and never exported. No scenario covers that count, and both tests
# pass. It is the kind of defect verify's Code health step exists for: the
# spec checks pass, the code still loses data.
set -eu

CHANGE=sk/changes/us-22100-order-export-batches
mkdir -p "$CHANGE/specs/order-export" sk/specs sk/changes/archive src test

cat > sk/config.yaml <<'EOF2'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

rules:
  tasks:
    - Named exports only

sensitive: []
EOF2

cat > src/order.ts <<'EOF2'
export interface Order {
  id: string;
  totalCents: number;
}
EOF2

cat > src/order-batches.ts <<'EOF2'
import type { Order } from './order';

export const BATCH_SIZE = 50;

export function toBatches(orders: Order[]): Order[][] {
  const batches: Order[][] = [];
  for (let start = 0; start < orders.length - 1; start += BATCH_SIZE) {
    batches.push(orders.slice(start, start + BATCH_SIZE));
  }
  return batches;
}
EOF2

cat > test/order-batches.test.ts <<'EOF2'
import { describe, expect, it } from 'vitest';
import type { Order } from '../src/order';
import { toBatches } from '../src/order-batches';

const orders = (n: number): Order[] =>
  Array.from({ length: n }, (_, i) => ({ id: `o-${i + 1}`, totalCents: 1000 }));

describe('toBatches', () => {
  it('splits 120 pending orders into batches of 50, 50 and 20', () => {
    expect(toBatches(orders(120)).map((b) => b.length)).toEqual([50, 50, 20]);
  });

  it('makes no batch when nothing is pending', () => {
    expect(toBatches([])).toEqual([]);
  });
});
EOF2

cat > "$CHANGE/proposal.md" <<'EOF2'
# 22100 — Export pending orders in batches

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/22100
**Type / State:** User Story / Active
**AC source:** work item

## Summary

The order export sends every pending order in one request, which the partner
endpoint rejects above 50 orders. Pending orders are to be grouped into batches
of at most 50 before they are sent.

## Capabilities

**Added:** `order-export` — batching pending orders

## Design

Skipped — no technical trade-off; one pure function.
EOF2

cat > "$CHANGE/specs/order-export/spec.md" <<'EOF2'
## ADDED Requirements

### Requirement: Pending orders are exported in batches

The order export SHALL group pending orders into batches of at most 50 orders,
in their original order.

#### Scenario: More pending orders than one batch holds

- **WHEN** 120 orders are pending
- **THEN** the export SHALL produce three batches of 50, 50 and 20 orders

#### Scenario: Nothing pending

- **WHEN** no order is pending
- **THEN** the export SHALL produce no batch
EOF2

cat > "$CHANGE/tasks.md" <<'EOF2'
## 1. Batching

- [x] 1.1 Add `src/order-batches.ts` exporting `BATCH_SIZE = 50` and `toBatches(orders)`, which returns the orders in consecutive batches of at most `BATCH_SIZE`
- [x] 1.2 Tests covering the scenarios this change added
EOF2
