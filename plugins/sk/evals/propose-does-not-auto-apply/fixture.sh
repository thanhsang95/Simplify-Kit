#!/usr/bin/env bash
# Seeds an initialised sk/ workspace, a little code, and an offline copy of an
# Azure DevOps work item with usable acceptance criteria — Branch A, cleanly.
#
# No change directory is pre-seeded: /sk:propose has to create
# sk/changes/us-20700-lowstock-badge/ itself, in the same run that also asks
# it to build the thing. Nothing here pre-implements the badge, so a
# grep for it after the run only finds what this run itself wrote.
set -eu

mkdir -p sk/specs sk/changes/archive src

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

rules:
  tasks:
    - Every behavioural change carries a vitest case

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
EOF

cat > src/product-card.ts <<'EOF'
export interface ProductCardProps {
  id: string;
  title: string;
  inventoryQty: number;
  trackInventory: boolean;
}

export function renderProductCard(props: ProductCardProps): string {
  return `<div class="product-card">${props.title}</div>`;
}
EOF

cat > work-item-20700.json <<'EOF'
{
  "id": 20700,
  "rev": 3,
  "fields": {
    "System.Id": 20700,
    "System.WorkItemType": "User Story",
    "System.State": "Active",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.IterationPath": "CatalogPortal\\Sprint 44",
    "System.Title": "Show a low-stock badge on product cards",
    "System.Description": "<div>As a shopper, I want product cards to show when an item is running low on stock so that I know to buy soon.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<div><b>Badge display</b><ul><li>A &quot;Low stock&quot; badge appears on a product card when the item&#39;s inventory quantity is at or below 5 units. </li><li>The badge does not appear when inventory is above 5 units, or when inventory tracking is disabled for that product. </li><li>The badge reuses the existing badge component &mdash; its text and color come from that component&#39;s props, not new hardcoded markup. </li></ul></div>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/20700"
}
EOF
