#!/usr/bin/env bash
# A work item with no acceptance criteria of its own, Related to another work
# item that already specifies the behaviour in full.
#
# This is the motivating case for reading `relations[]` in Branch B: a User
# Story with thin AC sits next to a Related item that already has the answer,
# and propose used to ask a blank question instead of noticing it. Product,
# org and work item ids are invented; no person, email or contract identifier
# appears here.
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

cat > src/download.ts <<'EOF'
export async function prepareDownload(catalogId: string): Promise<string> {
  return `/downloads/${catalogId}.csv`;
}
EOF

cat > work-item-20800.json <<'EOF'
{
  "id": 20800,
  "rev": 3,
  "fields": {
    "System.Id": 20800,
    "System.WorkItemType": "User Story",
    "System.State": "New",
    "System.Title": "Add bulk export to the catalog download page",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Publishers want to export more than one catalog at a time from the download page.</div>"
  },
  "relations": [
    {
      "rel": "System.LinkTypes.Related",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/20801",
      "attributes": { "name": "Related" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/20800"
}
EOF

cat > work-item-20801.json <<'EOF'
{
  "id": 20801,
  "rev": 5,
  "fields": {
    "System.Id": 20801,
    "System.WorkItemType": "User Story",
    "System.State": "Closed",
    "System.Title": "Bulk export controls for the supplier catalog page",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Suppliers asked for the same multi-select export already shipped on the catalog page.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>A checkbox appears beside each catalog row, and an &quot;Export selected&quot; button becomes enabled once at least one row is checked. </li><li>Selecting &quot;Export selected&quot; downloads a single .zip file containing one CSV per selected catalog. </li><li>While the export is being prepared, the button shows a spinner and is disabled to prevent duplicate requests. </li><li>If a selected catalog fails to export, the .zip still contains the catalogs that succeeded, and the failed ones are listed in a manifest.txt included in the archive. </li></ol>"
  },
  "relations": [
    {
      "rel": "System.LinkTypes.Related",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/20800",
      "attributes": { "name": "Related" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/20801"
}
EOF
