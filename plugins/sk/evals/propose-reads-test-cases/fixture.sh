#!/usr/bin/env bash
# A User Story with usable acceptance criteria and one Test Case linked by
# Tested By. The test case's steps arrive in the real shape: XML whose
# parameterizedString text is HTML escaped inside XML, so it decodes twice.
#
# Step 1's expected result is covered by AC 1. Step 2's pins the exact message
# AC 2 leaves open. Step 3's (duplicate names) is covered by no criterion: it
# must surface as a question / Gap, not as a scenario nobody asked for.
# Product, org and work item ids are invented; no person, email or contract
# identifier appears here.
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

cat > src/catalog.ts <<'EOF'
export interface Catalog { id: string; name: string }

export function renameCatalog(catalog: Catalog, name: string): Catalog {
  return { ...catalog, name };
}
EOF

cat > work-item-21300.json <<'EOF'
{
  "id": 21300,
  "rev": 6,
  "fields": {
    "System.Id": 21300,
    "System.WorkItemType": "User Story",
    "System.State": "Active",
    "System.Title": "Rename a catalog from its detail page",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Description": "<div>Publishers currently have to delete and re-create a catalog to fix a typo in its name.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>A publisher can rename a catalog from its detail page, and the new name shows everywhere the catalog is listed. </li><li>An empty name is rejected with an error message, and the catalog keeps its old name. </li></ol>"
  },
  "relations": [
    {
      "rel": "Microsoft.VSTS.Common.TestedBy-Forward",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21301",
      "attributes": { "name": "Tested By" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21300"
}
EOF

cat > work-item-21301.json <<'EOF'
{
  "id": 21301,
  "rev": 3,
  "fields": {
    "System.Id": 21301,
    "System.WorkItemType": "Test Case",
    "System.State": "Ready",
    "System.Title": "Rename catalog: happy path and validation",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "Microsoft.VSTS.TCM.Steps": "<steps id=\"0\" last=\"4\"><step id=\"2\" type=\"ValidateStep\"><parameterizedString isformatted=\"true\">&lt;DIV&gt;&lt;P&gt;Open the catalog &amp;quot;Sprng 2027&amp;quot; and rename it to &amp;quot;Spring 2027&amp;quot;.&lt;/P&gt;&lt;/DIV&gt;</parameterizedString><parameterizedString isformatted=\"true\">&lt;DIV&gt;&lt;P&gt;&amp;quot;Spring 2027&amp;quot; shows on the detail page and in the catalog list.&lt;/P&gt;&lt;/DIV&gt;</parameterizedString><description/></step><step id=\"3\" type=\"ValidateStep\"><parameterizedString isformatted=\"true\">&lt;DIV&gt;&lt;P&gt;Clear the name and save.&lt;/P&gt;&lt;/DIV&gt;</parameterizedString><parameterizedString isformatted=\"true\">&lt;DIV&gt;&lt;P&gt;The message &amp;quot;Name is required&amp;quot; appears and the name is unchanged.&lt;/P&gt;&lt;/DIV&gt;</parameterizedString><description/></step><step id=\"4\" type=\"ValidateStep\"><parameterizedString isformatted=\"true\">&lt;DIV&gt;&lt;P&gt;Rename it to &amp;quot;Autumn&amp;quot;, a name another catalog already uses.&lt;/P&gt;&lt;/DIV&gt;</parameterizedString><parameterizedString isformatted=\"true\">&lt;DIV&gt;&lt;P&gt;The message &amp;quot;A catalog with this name already exists&amp;quot; appears and the name is unchanged.&lt;/P&gt;&lt;/DIV&gt;</parameterizedString><description/></step></steps>"
  },
  "relations": [
    {
      "rel": "Microsoft.VSTS.Common.TestedBy-Reverse",
      "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21300",
      "attributes": { "name": "Tests" }
    }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21301"
}
EOF
