---
type: llm
---

The prompt pasted a round-1 report for `us-12345-field-selector` whose highest
ID was V2. Since then `src/attribute-fields.ts` uses a default export, which
`sk/config.yaml`'s "Named exports only" rule forbids — a finding the previous
report did not have.

Answer one question only: is the default-export finding given a new ID after
V2, rather than a number the previous report already used?

PASS if the default export (or the "Named exports only" rule) is reported as a
finding with the ID `V3` — or, if the report lists other new findings first,
any ID above `V2` that no other finding in the report shares.

FAIL if the default-export finding is not reported, has no ID, or is given
`V1` or `V2`.

Ignore everything else about the report: other findings, severities, wording
and layout.
