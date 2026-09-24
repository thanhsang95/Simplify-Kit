#!/usr/bin/env bash
# A work item with no acceptance criteria of its own, Related to another work
# item whose content has nothing to do with its gap.
#
# This is the adversarial mirror of propose-related-item-fills-gap: the
# Related link is real, but the item it points at is noise — a different
# surface entirely — so propose must not manufacture a confirmation question
# out of it. Product, org and work item ids are invented; no person, email
# or contract identifier appears here.
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

cat > src/search.ts <<'EOF'
export function filterCatalogs(catalogs: Array<{ expiresAt: string }>): typeof catalogs {
  return catalogs;
}
EOF

cat > work-item-21000.json <<'EOF'
{
  "id": 21000,
  "rev": 2,
  "fields": {
    "System.Id": 21000,
    "System.WorkItemType": "User Story",
    "System.State": "New",
    "System.Title": "Add an expiry-date filter to the catalog search page",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Buyers want to filter catalog search results by expiry date.</div>"
  },
  "relations": [
    {
      "rel": "System.LinkTypes.Related",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21001",
      "attributes": { "name": "Related" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21000"
}
EOF

cat > work-item-21001.json <<'EOF'
{
  "id": 21001,
  "rev": 4,
  "fields": {
    "System.Id": 21001,
    "System.WorkItemType": "Bug",
    "System.State": "Closed",
    "System.Title": "Dark mode toggle flickers on Safari in admin settings",
    "System.AreaPath": "CatalogPortal\\Platform",
    "System.Description": "<div>Toggling dark mode in the admin settings panel causes a brief flash of the light theme before the dark stylesheet applies, only on Safari.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>Toggling dark mode in admin settings applies the dark stylesheet with no visible flash of the light theme, on Safari as well as Chrome and Firefox. </li><li>The chosen theme persists across a page reload. </li></ol>"
  },
  "relations": [
    {
      "rel": "System.LinkTypes.Related",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21000",
      "attributes": { "name": "Related" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21001"
}
EOF
