#!/usr/bin/env bash
# An initialised workspace and a work item whose acceptance criteria mix three
# pinned-down criteria with two that read fluently but leave a decidable token
# undecided — no retry count, no size threshold for "very large".
#
# The shape matters: nothing here is worded as a question or flagged by the
# author as unclear. It reads like ordinary, confident AC, which is exactly
# the case the old "cannot turn into observable behaviour" Gaps rule missed —
# these can all be turned into a WHEN/THEN, just not down to one value.
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

cat > src/csv-export.ts <<'EOF'
export async function exportProductsCsv(filters: Record<string, string>): Promise<string> {
  return `/exports/products-${Date.now()}.csv`;
}
EOF

cat > work-item-31200.json <<'EOF'
{
  "id": 31200,
  "rev": 3,
  "fields": {
    "System.Id": 31200,
    "System.WorkItemType": "User Story",
    "System.State": "Active",
    "System.Title": "Make CSV export from the products list reliable",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Exporting the products list to CSV sometimes fails silently on large catalogs, and admins have no indication it is working while it processes.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>When an administrator clicks &quot;Export CSV&quot; on the products list, the system generates a CSV file containing every row currently visible after all filters and search have been applied &mdash; no more rows and no fewer. </li><li>The downloaded file is named <code>products-export-YYYY-MM-DD.csv</code>, using the current date in that exact format. </li><li>If the export request fails, the system retries the request automatically before giving up. </li><li>When an export contains a very large number of rows, the system shows a progress indicator instead of blocking the UI. </li><li>Only users with the Catalog Manager role can trigger an export &mdash; the &quot;Export CSV&quot; button is not shown to anyone else. </li></ol>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/31200"
}
EOF
