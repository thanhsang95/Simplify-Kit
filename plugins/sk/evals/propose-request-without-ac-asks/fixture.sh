#!/usr/bin/env bash
# An initialised workspace and a little code — and deliberately no work item
# anywhere. The request arrives in the prompt, and it is the kind that states
# a wish, not acceptance criteria.
set -eu

mkdir -p sk/specs sk/changes/archive src

cat > sk/config.yaml <<'YAML'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

rules:
  specs:
    - Describe observable behaviour, not internal mechanism

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
YAML

cat > src/inventory-report.ts <<'TS'
export interface InventoryRow {
  sku: string;
  name: string;
  onHand: number;
}

export async function loadInventoryReport(): Promise<InventoryRow[]> {
  return [];
}
TS
