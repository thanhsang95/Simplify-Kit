#!/usr/bin/env bash
# Seeds an initialised sk/ workspace, a little code, and an offline copy of an
# Azure DevOps work item.
#
# The work item keeps the HTML shape real criteria arrive in — <ol><li>, &quot;
# entities, one long flat list the reader has to group themselves. Product and
# customer names have been replaced; no person, email or contract identifier
# appears anywhere in it.
set -eu

mkdir -p sk/specs sk/changes/archive src

cat > sk/config.yaml <<'EOF'
context: |
  Stack: TypeScript 5.6, Node 20, vitest
  Build: npm run build
  Test: npm test

  Read before implementing:
  - docs/code-standards.md — naming, error handling, test placement

rules:
  specs:
    - Describe observable behaviour, not internal mechanism
  tasks:
    - Every behavioural change carries a vitest case

ado:
  orgUrl: "https://example-org.visualstudio.com/"
  project: "CatalogPortal"
EOF

cat > src/field-selector.ts <<'EOF'
export interface StandardField {
  key: string;
  label: string;
}

export function listStandardFields(): StandardField[] {
  return [
    { key: 'product_title', label: 'Product Title' },
    { key: 'product_description', label: 'Product Description' },
  ];
}
EOF

cat > src/transform.ts <<'EOF'
export type TransformFn = 'character_limit' | 'force_uppercase' | 'trim_whitespace';

export function applyTransform(value: string, fn: TransformFn): string {
  switch (fn) {
    case 'force_uppercase':
      return value.toUpperCase();
    case 'trim_whitespace':
      return value.trim();
    default:
      return value;
  }
}
EOF

cat > work-item-12345.json <<'EOF'
{
  "id": 12345,
  "rev": 7,
  "fields": {
    "System.Id": 12345,
    "System.WorkItemType": "User Story",
    "System.State": "Active",
    "System.Title": "Add product attributes to the data transformation rule field selector",
    "System.AreaPath": "CatalogPortal\\Delivery",
    "System.IterationPath": "CatalogPortal\\Sprint 41",
    "System.Description": "<div>As a system administrator, I want to select product attributes in addition to standard product fields when creating a data transformation rule so that I can apply transformation functions &mdash; such as character limits, case formatting, and special character removal &mdash; to attribute values before they are delivered to an endpoint.</div>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ol dir=ltr><li>The &quot;Select a field&quot; dropdown in the Add field rule panel is expanded to include all product attributes available in the catalog portal in addition to the existing standard product fields. </li><li>Attributes are displayed in the dropdown as a clearly labeled separate group beneath the existing standard fields &mdash; for example a section header &quot;Attributes&quot; separating them from the existing &quot;Standard Fields&quot; section header &mdash; so administrators can navigate the list without confusion between field types. </li><li>Each attribute entry in the dropdown displays the attribute display name and its API field key in the same two-column format used for standard fields in the current UI &mdash; for example &quot;Color Description&quot; and <code>color_description</code> displayed side by side. </li><li>The existing search bar within the field selector searches across both standard fields and attributes simultaneously &mdash; entering a term filters both lists to matching items so administrators can find any field or attribute without knowing which section it lives in. </li><li>All transformation functions currently available for standard fields &mdash; character limit, remove special characters, force uppercase, force lowercase, title case, strip HTML tags, replace value, and trim whitespace &mdash; are available for attribute fields without restriction. The function selection step of the rule builder behaves identically whether a standard field or an attribute is selected. </li><li>The live preview panel on the right side of the Add field rule modal works for attribute fields in the same way as standard fields. The administrator can paste a sample value and see the transformation output before saving the rule. </li><li>Custom attributes created by publishers on their own accounts are not included in the system-level transformation rule field selector &mdash; only system-defined attributes are available. </li><li>When a transformation rule targets an attribute field and that attribute is not present on a specific product being delivered to the endpoint, the transformation rule is skipped for that product without error &mdash; consistent with how missing standard fields are handled. </li><li>Existing transformation rules that target standard fields are not affected by this change &mdash; no existing rules are modified or require reconfiguration. </li><li>The attribute list in the field selector reflects the current system-defined attribute library at the time the administrator opens the rule builder &mdash; if new system attributes are added they appear in the selector without requiring a code deployment. </li></ol>"
  },
  "relations": [],
  "url": "https://example-org.visualstudio.com/_apis/wit/workItems/12345"
}
EOF
