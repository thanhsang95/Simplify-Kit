#!/usr/bin/env bash
# A User Story whose acceptance criteria include a CSV export, and a later
# comment that takes the export out of this story. The comment wins, and the
# dropped export must be recorded as a decision under ## Out of scope, not
# simply left without a scenario where it looks forgotten. Product, org and
# work item ids are invented; no person, email or contract identifier
# appears here (the comment author is a role, not a name).
set -eu

mkdir -p sk/specs sk/changes/archive src

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

cat > src/price.ts <<'EOF'
export interface PriceChange { sku: string; price: number; changedOn: string }
EOF

cat > work-item-21400.json <<'EOF'
{
  "id": 21400,
  "rev": 7,
  "fields": {
    "System.Id": 21400,
    "System.WorkItemType": "User Story",
    "System.State": "Active",
    "System.Title": "Show the price history of a product",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Publishers want to see how a product&#39;s price changed over time.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>The product detail page has a &quot;Price history&quot; tab listing every price change, newest first, with the date and the new price. </li><li>A product with no price change shows &quot;No price changes yet&quot;. </li><li>The list can be exported as a CSV file. </li></ol>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21400"
}
EOF

cat > work-item-21400-comments.json <<'EOF'
{
  "totalCount": 1,
  "count": 1,
  "comments": [
    {
      "id": 1,
      "workItemId": 21400,
      "text": "<div>Agreed with the product owner today: the CSV export (criterion 3) is <b>not</b> part of this story. It moves to AB#21410.</div>",
      "createdBy": { "displayName": "Product Owner" },
      "createdDate": "2026-10-20T09:15:00Z"
    }
  ]
}
EOF
