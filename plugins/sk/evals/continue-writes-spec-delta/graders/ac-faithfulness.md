---
type: llm
focus:
  source: file
  path: sk/changes/us-12345-field-selector/specs/field-selector/spec.md
---

The file under review is a specification generated from a work item whose
acceptance criteria were, word for word:

1. The "Select a field" dropdown in the Add field rule panel is expanded to include all product attributes available in the catalog portal in addition to the existing standard product fields.
2. Attributes are displayed in the dropdown as a clearly labeled separate group beneath the existing standard fields — for example a section header "Attributes" separating them from the existing "Standard Fields" section header — so administrators can navigate the list without confusion between field types.
3. Each attribute entry in the dropdown displays the attribute display name and its API field key in the same two-column format used for standard fields in the current UI — for example "Color Description" and color_description displayed side by side.
4. The existing search bar within the field selector searches across both standard fields and attributes simultaneously — entering a term filters both lists to matching items so administrators can find any field or attribute without knowing which section it lives in.
5. All transformation functions currently available for standard fields — character limit, remove special characters, force uppercase, force lowercase, title case, strip HTML tags, replace value, and trim whitespace — are available for attribute fields without restriction. The function selection step of the rule builder behaves identically whether a standard field or an attribute is selected.
6. The live preview panel on the right side of the Add field rule modal works for attribute fields in the same way as standard fields. The administrator can paste a sample value and see the transformation output before saving the rule.
7. Custom attributes created by publishers on their own accounts are not included in the system-level transformation rule field selector — only system-defined attributes are available.
8. When a transformation rule targets an attribute field and that attribute is not present on a specific product being delivered to the endpoint, the transformation rule is skipped for that product without error — consistent with how missing standard fields are handled.
9. Existing transformation rules that target standard fields are not affected by this change — no existing rules are modified or require reconfiguration.
10. The attribute list in the field selector reflects the current system-defined attribute library at the time the administrator opens the rule builder — if new system attributes are added they appear in the selector without requiring a code deployment.

A marker of the form [[OPEN:Q1]] is an unanswered question, not a stated
behaviour: a scenario whose outcome is such a marker states nothing and must
not count against the file.

PASS if every requirement and scenario in the file traces back to one of those
ten criteria, and the file states no behaviour that none of them mentions.
Partial coverage is acceptable — criteria may legitimately be recorded as gaps
elsewhere and left out of the spec.

FAIL if the file specifies behaviour that appears in none of the ten criteria:
invented UI elements, invented permissions or roles, invented error handling,
invented performance or timing requirements, invented persistence or migration
behaviour. Judge only whether the content is traceable, not how it is worded,
formatted, grouped, or how many requirements it was split into.
