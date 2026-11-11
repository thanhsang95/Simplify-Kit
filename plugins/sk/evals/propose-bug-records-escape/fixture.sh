#!/usr/bin/env bash
# A Bug whose comment says when it started ("after last week's release") but
# names no PR or change. The Escape questions accept "unknown"; unattended, the
# cause must stay unknown rather than become a PR id the model made up, because
# /sk:learn counts escapes from these lines. Product, org and work item ids are
# invented; no person, email or contract identifier appears here.
set -eu

mkdir -p sk/specs/price-list sk/changes/archive src

cat > sk/config.yaml <<'EOF'
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
EOF

cat > sk/specs/price-list/spec.md <<'EOF'
# price-list

### Requirement: Price list shows each item's unit price

The price list page SHALL show every catalog item with its unit price.

#### Scenario: Items listed with prices

- **WHEN** a buyer opens the price list of a catalog
- **THEN** each item SHALL appear with its unit price in the catalog currency
EOF

cat > src/price.ts <<'EOF'
export function formatPrice(value: number): string {
  return (Math.floor(value * 100) / 100).toFixed(2);
}
EOF

cat > work-item-21600.json <<'EOF'
{
  "id": 21600,
  "rev": 3,
  "fields": {
    "System.Id": 21600,
    "System.WorkItemType": "Bug",
    "System.State": "Active",
    "System.Title": "Price list truncates unit prices instead of rounding them",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "Microsoft.VSTS.TCM.ReproSteps": "<div><b>Steps</b></div><ol><li>Open the price list of a catalog as a buyer.</li><li>Find an item whose unit price is 4.996.</li></ol><div><b>Expected result</b></div><div>The unit price is shown rounded to two decimals: &quot;5.00&quot;.</div><div><b>Actual result</b></div><div>The unit price is shown as &quot;4.99&quot;.</div>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21600"
}
EOF

cat > work-item-21600-comments.json <<'EOF'
{
  "totalCount": 1,
  "count": 1,
  "comments": [
    {
      "id": 1,
      "workItemId": 21600,
      "text": "<div>This started after last week&#39;s release. Before that the prices on this page were rounded correctly.</div>",
      "createdBy": { "displayName": "Support Lead" },
      "createdDate": "2026-11-03T08:40:00Z"
    }
  ]
}
EOF
