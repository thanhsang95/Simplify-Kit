---
type: llm
---

The change `us-12345-field-selector` has findings at more than one severity:
the search requirement has a ticked task and no code (critical), and
`src/attribute-fields.ts` uses a default export although `sk/config.yaml`
says "Named exports only" (a warning). There may be others.

Answer one question only: does every finding in the report carry its own ID
of the form `V<n>`, with the numbering running on across severity sections
rather than starting again at `V1` under each one?

PASS if every listed finding has a `V<n>` ID, no two findings share an ID, and
the IDs under a later severity continue from the earlier ones (for example
`V1` critical, `V2` and `V3` warnings).

FAIL if any finding has no ID, two findings share an ID, or the numbering
restarts in a later severity section (for example a second `V1` under
WARNING).

Ignore everything else about the report: which findings it lists, their
severities, wording and layout.
