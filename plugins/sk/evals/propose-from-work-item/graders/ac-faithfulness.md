---
type: llm
focus:
  source: file
  path: sk/changes/us-12345-field-selector/specs/field-selector/spec.md
---

The file under review is a specification generated from a work item whose
acceptance criteria stated, in substance:

1. The field selector dropdown includes product attributes alongside standard fields
2. Attributes appear as a separate labelled group beneath standard fields
3. Each attribute shows its display name and API field key, two columns, like standard fields
4. The search bar filters standard fields and attributes at the same time
5. Every transformation function available for standard fields is available for attributes, and function selection behaves identically
6. The live preview panel works for attribute fields as it does for standard fields
7. Publisher-created custom attributes are excluded; only system-defined attributes appear
8. When a targeted attribute is absent from a product, the rule is skipped for that product without error
9. Existing rules targeting standard fields are unaffected and need no reconfiguration
10. The attribute list reflects the current system-defined attribute library, with no code deployment needed for new attributes

PASS if every requirement and scenario in the file traces back to one of those
ten criteria, and the file states no behaviour that none of them mentions.
Partial coverage is acceptable — criteria may legitimately be recorded as gaps
elsewhere and left out of the spec.

FAIL if the file specifies behaviour that appears in none of the ten criteria:
invented UI elements, invented permissions or roles, invented error handling,
invented performance or timing requirements, invented persistence or migration
behaviour. Judge only whether the content is traceable, not how it is worded,
formatted, grouped, or how many requirements it was split into.
