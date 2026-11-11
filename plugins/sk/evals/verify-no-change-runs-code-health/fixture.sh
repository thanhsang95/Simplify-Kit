#!/usr/bin/env bash
# A refactor with no sk change behind it: src/price-format.ts now caches one
# Intl.NumberFormat per currency instead of building one per call. There is no
# open change under sk/changes/, only a living spec for an unrelated
# capability. Before code health existed, verify stopped here for want of a
# change; now it reviews the file and says the spec checks were skipped.
set -eu

mkdir -p sk/specs/order-export sk/changes/archive src test

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

cat > sk/specs/order-export/spec.md <<'EOF2'
# order-export

### Requirement: Pending orders are exported in batches

The order export SHALL group pending orders into batches of at most 50 orders,
in their original order.

#### Scenario: More pending orders than one batch holds

- **WHEN** 120 orders are pending
- **THEN** the export SHALL produce three batches of 50, 50 and 20 orders
EOF2

cat > src/price-format.ts <<'EOF2'
const formatters = new Map<string, Intl.NumberFormat>();

function formatterFor(currency: string): Intl.NumberFormat {
  let formatter = formatters.get(currency);
  if (!formatter) {
    formatter = new Intl.NumberFormat('en-US', { style: 'currency', currency });
    formatters.set(currency, formatter);
  }
  return formatter;
}

export function formatPrice(cents: number, currency: string): string {
  return formatterFor(currency).format(cents / 100);
}
EOF2

cat > test/price-format.test.ts <<'EOF2'
import { describe, expect, it } from 'vitest';
import { formatPrice } from '../src/price-format';

describe('formatPrice', () => {
  it('formats cents as a currency amount', () => {
    expect(formatPrice(123456, 'USD')).toBe('$1,234.56');
  });

  it('reuses the formatter for a currency it has seen', () => {
    expect(formatPrice(100, 'EUR')).toBe(formatPrice(100, 'EUR'));
  });
});
EOF2
