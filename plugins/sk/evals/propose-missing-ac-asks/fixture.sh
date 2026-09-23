#!/usr/bin/env bash
# An initialised workspace and a work item with no acceptance criteria at all.
#
# This is not a contrived case: roughly one user story in five arrives with the
# AcceptanceCriteria field absent and a description too thin to specify from.
# The shape here mirrors one of those.
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

cat > work-item-20600.json <<'EOF'
{
  "id": 20600,
  "rev": 2,
  "fields": {
    "System.Id": 20600,
    "System.WorkItemType": "User Story",
    "System.State": "New",
    "System.Title": "Improve the catalog download experience",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Downloads feel slow for large catalogs.</div>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/20600"
}
EOF
