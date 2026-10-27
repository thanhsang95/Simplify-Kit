#!/usr/bin/env bash
# A Bug with no acceptance criteria field. Its repro steps hold the steps, an
# expected result and an actual result, the shape reporters actually type.
#
# Before the repro steps were read, every Bug landed in Branch B and the user
# was asked for criteria the board already held. The living spec covers
# search, but not the "Hide expired" filter, so this is a real change, not a
# fix that restores specified behaviour. Product, org and work item ids are
# invented; no person, email or contract identifier appears here.
set -eu

mkdir -p sk/specs/catalog-search sk/changes/archive src

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

cat > sk/specs/catalog-search/spec.md <<'EOF'
# catalog-search

### Requirement: Search matches catalog names

The catalog page SHALL return catalogs whose name contains the search text.

#### Scenario: Case-insensitive match

- **WHEN** a publisher searches for "spring"
- **THEN** catalogs named "Spring 2027" and "SPRING clearance" SHALL both appear
EOF

cat > src/search.ts <<'EOF'
export interface Catalog { name: string; expiresOn: string }

export function searchCatalogs(all: Catalog[], text: string): Catalog[] {
  const q = text.toLowerCase();
  return all.filter((c) => c.name.toLowerCase().includes(q));
}
EOF

cat > work-item-21100.json <<'EOF'
{
  "id": 21100,
  "rev": 4,
  "fields": {
    "System.Id": 21100,
    "System.WorkItemType": "Bug",
    "System.State": "Active",
    "System.Title": "Search shows expired catalogs while &quot;Hide expired&quot; is on",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "Microsoft.VSTS.TCM.ReproSteps": "<div><b>Steps</b></div><ol><li>Open the catalog page as a publisher.</li><li>Turn on the &quot;Hide expired&quot; filter.</li><li>Search for &quot;spring&quot;.</li></ol><div><b>Expected result</b></div><div>Only catalogs whose expiry date is today or later appear in the results.</div><div><b>Actual result</b></div><div>Catalogs that expired last month still appear in the results, labelled &quot;Expired&quot;.</div>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21100"
}
EOF
