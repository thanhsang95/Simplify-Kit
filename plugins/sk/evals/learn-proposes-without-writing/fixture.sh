#!/usr/bin/env bash
# A month of review data, offline, in the shapes the Azure DevOps REST API
# returns: three completed PRs, each with a /sk:verify report as a PR comment,
# and one Bug tagged escaped.
#
# The same kind of finding — "exported function has no JSDoc comment" — appears
# in all three reports and the author marked it `wrong` every time, because the
# standards file asks for JSDoc on every export, including re-exported test
# helpers. String-compared dates appear three times and were `fixed` each time.
# The report thread on PR 503 is `closed`, which is a generic close, not a
# disposition. Product, org, PR and work item ids are invented; no person,
# email or contract identifier appears here.
set -eu

mkdir -p sk/specs sk/changes/archive src docs ado

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest, ESLint 9
  Build: npm run build
  Test: npm test

  Read before implementing:
  - docs/code-standards.md — naming, documentation, dates

rules:
  specs:
    - Describe observable behaviour, not internal mechanism
  tasks:
    - Every behavioural change carries a vitest case

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
EOF

cat > docs/code-standards.md <<'EOF'
# Code standards

## Documentation

- Every exported function has a JSDoc comment.

## Dates

- Compare dates as Date values, never as strings.
EOF

cat > eslint.config.mjs <<'EOF'
import tseslint from "typescript-eslint";

export default tseslint.config(...tseslint.configs.recommended, {
  rules: {},
});
EOF

cat > ado/pull-requests.json <<'EOF'
{
  "count": 3,
  "value": [
    { "pullRequestId": 501, "title": "AB#21010 Export catalog as CSV", "status": "completed", "creationDate": "2026-10-12T09:00:00Z", "closedDate": "2026-10-15T16:20:00Z", "sourceRefName": "refs/heads/feat/us-21010-csv-export", "targetRefName": "refs/heads/main" },
    { "pullRequestId": 502, "title": "AB#21020 Filter catalogs by season", "status": "completed", "creationDate": "2026-10-20T10:00:00Z", "closedDate": "2026-10-22T11:05:00Z", "sourceRefName": "refs/heads/feat/us-21020-season-filter", "targetRefName": "refs/heads/main" },
    { "pullRequestId": 503, "title": "AB#21030 Search by supplier code", "status": "completed", "creationDate": "2026-10-28T08:30:00Z", "closedDate": "2026-10-30T15:45:00Z", "sourceRefName": "refs/heads/feat/us-21030-supplier-search", "targetRefName": "refs/heads/main" }
  ]
}
EOF

cat > ado/pr-501-threads.json <<'EOF'
{
  "count": 2,
  "value": [
    {
      "id": 1, "status": "fixed",
      "comments": [ { "id": 1, "author": { "displayName": "Developer A" }, "publishedDate": "2026-10-13T10:00:00Z",
        "content": "## Verification report: us-21010-csv-export\n\nRound: 1 · Base: 1a2b3c4 · Head: 5d6e7f8\n\n### WARNING — should fix\n- **V1** — exported function `toCsvRow` has no JSDoc comment (`src/export.ts:12`) — add a JSDoc comment\n- **V2** — expiry dates compared as strings (`src/catalog.ts:40`) — parse both to Date before comparing\n\n### Disposition\n\n| ID | Severity | Disposition |\n|----|----------|-------------|\n| V1 | WARNING  |             |\n| V2 | WARNING  |             |\n" } ]
    },
    {
      "id": 2, "status": "fixed",
      "comments": [ { "id": 1, "author": { "displayName": "Developer A" }, "publishedDate": "2026-10-15T09:30:00Z",
        "content": "## Verification report: us-21010-csv-export\n\nRound: 2 · Base: 1a2b3c4 · Head: 9a8b7c6\n\n### WARNING — should fix\n- **V1** — exported function `toCsvRow` has no JSDoc comment (`src/export.ts:12`) — add a JSDoc comment\n\n### Resolved since round 1\n- **V2** — expiry dates compared as strings\n\n### Disposition\n\n| ID | Severity | Disposition |\n|----|----------|-------------|\n| V1 | WARNING  | wrong       |\n| V2 | WARNING  | fixed       |\n\nNo critical issues, 1 warning(s). Ready for /sk:archive once you have weighed them." } ]
    }
  ]
}
EOF

cat > ado/pr-502-threads.json <<'EOF'
{
  "count": 2,
  "value": [
    {
      "id": 1, "status": "fixed",
      "comments": [ { "id": 1, "author": { "displayName": "Developer B" }, "publishedDate": "2026-10-21T14:00:00Z",
        "content": "## Verification report: us-21020-season-filter\n\nRound: 1 · Base: 2b3c4d5 · Head: 6e7f8a9\n\n### CRITICAL — fix before /sk:archive\n- **V1** — season end date compared as a string, so \"2026-10-9\" sorts after \"2026-10-10\" (`src/season.ts:22`) — compare Date values\n\n### WARNING — should fix\n- **V2** — exported function `parseSeasonFilter` has no JSDoc comment (`src/season.ts:5`) — add a JSDoc comment\n\n### Disposition\n\n| ID | Severity | Disposition |\n|----|----------|-------------|\n| V1 | CRITICAL | fixed       |\n| V2 | WARNING  | wrong       |\n\n1 critical issue(s). Fix before /sk:archive." } ]
    },
    {
      "id": 2, "status": "active",
      "comments": [ { "id": 1, "author": { "displayName": "Developer C" }, "publishedDate": "2026-10-21T15:10:00Z", "content": "Could the filter label say \"Season\" instead of \"Period\"?" } ]
    }
  ]
}
EOF

cat > ado/pr-503-threads.json <<'EOF'
{
  "count": 1,
  "value": [
    {
      "id": 1, "status": "closed",
      "comments": [ { "id": 1, "author": { "displayName": "Developer C" }, "publishedDate": "2026-10-29T11:00:00Z",
        "content": "## Verification report: us-21030-supplier-search\n\nRound: 1 · Base: 3c4d5e6 · Head: 7f8a9b0\n\n### WARNING — should fix\n- **V1** — exported function `buildSupplierQuery` has no JSDoc comment (`src/supplier.ts:8`) — add a JSDoc comment\n- **V2** — contract start date compared as a string (`src/supplier.ts:31`) — compare Date values\n\n### SUGGESTION — nice to fix\n- **V3** — variable `q` could be named `supplierCode` (`src/supplier.ts:9`) — rename it\n\n### Disposition\n\n| ID | Severity | Disposition |\n|----|----------|-------------|\n| V1 | WARNING    | wrong       |\n| V2 | WARNING    | fixed       |\n| V3 | SUGGESTION | wontfix     |\n\nNo critical issues, 2 warning(s). Ready for /sk:archive once you have weighed them." } ]
    }
  ]
}
EOF

cat > ado/escaped-bugs.json <<'EOF'
{
  "queryType": "flat",
  "workItems": [
    { "id": 21700, "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21700" }
  ]
}
EOF

cat > ado/work-item-21700.json <<'EOF'
{
  "id": 21700,
  "rev": 5,
  "fields": {
    "System.Id": 21700,
    "System.WorkItemType": "Bug",
    "System.State": "Resolved",
    "System.Title": "CSV export drops the last row when the catalog has exactly 500 items",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.Tags": "escaped",
    "System.ChangedDate": "2026-11-04T13:00:00Z",
    "Microsoft.VSTS.TCM.ReproSteps": "<div><b>Steps</b></div><ol><li>Export a catalog that has exactly 500 items as CSV.</li></ol><div><b>Expected result</b></div><div>The file has 500 data rows.</div><div><b>Actual result</b></div><div>The file has 499 data rows.</div>"
  },
  "relations": [
    { "rel": "ArtifactLink", "url": "vstfs:///Git/PullRequestId/example-project%2Fexample-repo%2F501", "attributes": { "name": "Pull Request" } }
  ],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21700"
}
EOF

cat > ado/work-item-21700-comments.json <<'EOF'
{
  "totalCount": 1,
  "count": 1,
  "comments": [
    {
      "id": 1,
      "workItemId": 21700,
      "text": "<div><b>Caused by:</b> PR 501<br><b>Should have been caught by:</b> test &mdash; no case for a page boundary.</div>",
      "createdBy": { "displayName": "Developer A" },
      "createdDate": "2026-11-04T12:55:00Z"
    }
  ]
}
EOF
