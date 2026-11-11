#!/usr/bin/env bash
# An open change in code review (every task ticked). proposal.md rated it
# Low, two-way before any code existed, but design.md renames a field of an
# existing endpoint the partner price feed already reads — a one-way door. The
# Merge danger must say the risk went up from Low and why, and suggest
# risk:high. Product, org and work item ids are invented; no person, email or
# contract identifier appears here.
set -eu

C=sk/changes/us-21900-unit-price
mkdir -p "$C/specs/product-api" sk/specs/product-api sk/changes/archive src/api

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Test: npm test

sensitive:
  - src/Auth/**

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
EOF

cat > src/api/products.ts <<'EOF'
export interface ProductDetail {
  sku: string;
  title: string;
  unitPrice: number;
  currency: string;
}

// GET /api/products/{sku}
export function getProduct(sku: string): ProductDetail {
  return { sku, title: '', unitPrice: 0, currency: 'EUR' };
}
EOF

cat > sk/specs/product-api/spec.md <<'EOF'
# product-api

### Requirement: Product detail returns its price

`GET /api/products/{sku}` SHALL return the product's price and currency.

#### Scenario: Product with a price

- **WHEN** a caller requests a product whose price is 12.50 EUR
- **THEN** the response SHALL contain `"price": 12.5` and `"currency": "EUR"`

#### Scenario: Unknown product

- **WHEN** a caller requests a SKU that does not exist
- **THEN** the response SHALL be 404
EOF

cat > "$C/proposal.md" <<'EOF'
# 21900 — Call the product price "unitPrice" in the product API

**Work item:** https://example-org.visualstudio.com/CatalogPortal/_workitems/edit/21900
**Type / State:** User Story / Active
**AC source:** work item

## Summary

The product detail response names its price field `unitPrice` instead of
`price`, to match the order API.

## Capabilities

**Modified:** `product-api` — the price field is renamed

## Assumptions

- The currency field keeps its name — unconfirmed

## Open questions

## Gaps

## Impact

- `src/api/products.ts` — the response field is renamed

## Risk (preliminary)

**Level:** Low — unconfirmed
**Door:** two-way — a rename in one response; reverting the commit restores it
**Sensitive areas:** none matched
**Early review:** no
EOF

cat > "$C/specs/product-api/spec.md" <<'EOF'
## MODIFIED Requirements

### Requirement: Product detail returns its price

`GET /api/products/{sku}` SHALL return the product's price as `unitPrice`,
and its currency.

#### Scenario: Product with a price

- **WHEN** a caller requests a product whose price is 12.50 EUR
- **THEN** the response SHALL contain `"unitPrice": 12.5` and `"currency": "EUR"`, and no `price` field

#### Scenario: Unknown product

- **WHEN** a caller requests a SKU that does not exist
- **THEN** the response SHALL be 404
EOF

cat > "$C/design.md" <<'EOF'
# Design — us-21900-unit-price

## Contracts

### `GET /api/products/{sku}` — src/api/products.ts

```ts
export interface ProductDetail {
  sku: string;
  title: string;
  unitPrice: number;
  currency: string;
}
```

- **Serves:** Product with a price; Unknown product
- **Errors:** 404 for an unknown SKU
- **Changes:** changed from `price: number` — breaks the partner price feed, which reads `price` from this endpoint every night
EOF

cat > "$C/tasks.md" <<'EOF'
## 1. Rename the price field

- [x] 1.1 Rename `price` to `unitPrice` in `ProductDetail` in `src/api/products.ts`
- [x] 1.2 Return `unitPrice` from `GET /api/products/{sku}`
- [x] 1.3 Update the vitest cases for "Product with a price"
EOF
