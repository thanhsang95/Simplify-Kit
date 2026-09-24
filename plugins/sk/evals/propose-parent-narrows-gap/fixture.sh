#!/usr/bin/env bash
# A User Story with an empty description, no acceptance criteria field, and
# no `Related` link at all — its only connected items are a Hierarchy-Reverse
# parent Feature (which has real content) and a Hierarchy-Forward child Task
# (an implementation checklist, no AC of its own).
#
# This is the shape that motivated the parent-narrows-gap rule: the shipped
# Related-only fix does nothing here, because there is no Related entry to
# read, and the Task cascade does not fire either, because the current item
# is a User Story, not a Task. Product, org and work item ids are invented;
# no person, email or contract identifier appears here.
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

cat > src/catalog-sync.ts <<'EOF'
export async function runCatalogSync(publisherId: string): Promise<void> {
  // placeholder for the legacy sync worker
}
EOF

cat > work-item-21200.json <<'EOF'
{
  "id": 21200,
  "rev": 2,
  "fields": {
    "System.Id": 21200,
    "System.WorkItemType": "User Story",
    "System.State": "New",
    "System.Title": "Verify catalog sync results",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": ""
  },
  "relations": [
    {
      "rel": "System.LinkTypes.Hierarchy-Reverse",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21201",
      "attributes": { "name": "Parent" }
    },
    {
      "rel": "System.LinkTypes.Hierarchy-Forward",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21202",
      "attributes": { "name": "Child" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21200"
}
EOF

cat > work-item-21201.json <<'EOF'
{
  "id": 21201,
  "rev": 9,
  "fields": {
    "System.Id": 21201,
    "System.WorkItemType": "Feature",
    "System.State": "Resolved",
    "System.Title": "Migrate catalog sync to the new delivery pipeline",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Catalog sync currently runs on the legacy delivery worker, which cannot be scaled independently of the web tier. This feature moves catalog sync onto the new delivery pipeline so it can be scaled and monitored on its own.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>Catalog sync jobs run on the new delivery pipeline instead of the legacy delivery worker, for every publisher account. </li><li>Sync throughput and failure counts are visible on the new pipeline&#39;s existing monitoring dashboard. </li><li>A sync job that fails on the new pipeline retries automatically up to 3 times before being marked failed, matching the legacy worker&#39;s retry behavior. </li><li>No publisher-visible change in sync timing or output format results from this migration. </li></ol>"
  },
  "relations": [
    {
      "rel": "System.LinkTypes.Hierarchy-Forward",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21200",
      "attributes": { "name": "Child" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21201"
}
EOF

cat > work-item-21202.json <<'EOF'
{
  "id": 21202,
  "rev": 2,
  "fields": {
    "System.Id": 21202,
    "System.WorkItemType": "Task",
    "System.State": "New",
    "System.Title": "Update sync worker deployment config",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Point the sync worker at the new pipeline&#39;s deployment target and update the environment variables.</div>"
  },
  "relations": [
    {
      "rel": "System.LinkTypes.Hierarchy-Reverse",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21200",
      "attributes": { "name": "Parent" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21202"
}
EOF
