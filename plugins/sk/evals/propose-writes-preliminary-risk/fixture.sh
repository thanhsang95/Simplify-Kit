#!/usr/bin/env bash
# A User Story whose criteria change how sign-in sessions end, in code that
# lives under src/Auth/ — a path sk/config.yaml lists under `sensitive:`.
# /sk:propose must write ## Risk (preliminary) rated at least Medium, name the
# sensitive glob and ask for an early review. Product, org and work item ids
# are invented; no person, email or contract identifier appears here.
set -eu

mkdir -p sk/specs sk/changes/archive src/Auth

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

rules:
  specs:
    - Describe observable behaviour, not internal mechanism

sensitive:
  - src/Auth/**
  - .azure-pipelines/**

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
EOF

cat > src/Auth/session.ts <<'EOF'
export interface Session {
  id: string;
  accountId: string;
  createdOn: string;
}

export function listSessions(accountId: string): Session[] {
  return [];
}

export function endSession(sessionId: string): void {
  // removes the session from the session store
}
EOF

cat > src/Auth/password.ts <<'EOF'
export function changePassword(accountId: string, newPassword: string): void {
  // stores the new password hash
}
EOF

cat > work-item-21500.json <<'EOF'
{
  "id": 21500,
  "rev": 4,
  "fields": {
    "System.Id": 21500,
    "System.WorkItemType": "User Story",
    "System.State": "Active",
    "System.Title": "Sign out other sessions after a password change",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.IterationPath": "CatalogPortal\\Sprint 44",
    "System.Description": "<div>As a catalog portal user, when I change my password I want every other place I am signed in to be signed out, so that someone who learned my old password cannot keep using a session they already opened.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>When a user changes their password, every other session of that account is signed out. </li><li>The session the password was changed from stays signed in. </li><li>A signed-out session that makes its next request is sent to the sign-in page with the message &quot;Your password was changed. Please sign in again.&quot; </li></ol>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/21500"
}
EOF
