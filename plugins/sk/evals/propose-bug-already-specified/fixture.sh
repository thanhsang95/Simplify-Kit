#!/usr/bin/env bash
# A Bug whose expected result the living spec already states word for word.
# The code drifted; the spec is right. A change here would have nothing for
# its spec delta to say, so /sk:propose should create none and point at the
# existing scenario instead. Product, org and work item ids are invented; no
# person, email or contract identifier appears here.
set -eu

mkdir -p sk/specs/catalog-download sk/changes/archive src

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

cat > sk/specs/catalog-download/spec.md <<'EOF'
# catalog-download

### Requirement: A catalog downloads as one CSV file

The download page SHALL deliver a catalog as a single CSV file named after the catalog.

#### Scenario: Plain catalog name

- **WHEN** a publisher downloads the catalog "Autumn"
- **THEN** a file named "Autumn.csv" SHALL download

#### Scenario: Catalog name with spaces

- **WHEN** a publisher downloads a catalog whose name contains spaces, such as "Spring Sale 2027"
- **THEN** a file named "Spring-Sale-2027.csv" SHALL download, with each space replaced by a hyphen
EOF

cat > src/download.ts <<'EOF'
export function downloadPath(catalogName: string): string {
  return `/downloads/${catalogName}.csv`;
}
EOF

cat > work-item-21200.json <<'EOF'
{
  "id": 21200,
  "rev": 2,
  "fields": {
    "System.Id": 21200,
    "System.WorkItemType": "Bug",
    "System.State": "New",
    "System.Title": "Downloading a catalog with spaces in its name returns 404",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "Microsoft.VSTS.TCM.ReproSteps": "<div><b>Steps</b></div><ol><li>Create a catalog named &quot;Spring Sale 2027&quot;.</li><li>Open the download page and download it.</li></ol><div><b>Expected result</b></div><div>A file named &quot;Spring-Sale-2027.csv&quot; downloads.</div><div><b>Actual result</b></div><div>The browser shows a 404 page.</div>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21200"
}
EOF
