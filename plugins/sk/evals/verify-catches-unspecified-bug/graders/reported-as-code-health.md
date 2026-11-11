---
type: llm
---

The change `us-22100-order-export-batches` implements its one requirement and
both scenarios (120 orders → 50, 50, 20; no orders → no batch), and tests
cover both. Separately, `toBatches` in `src/order-batches.ts` drops the last
order when the count is one more than a multiple of 50. No requirement or
scenario mentions that count, so it is a code defect, not a spec failure.
`/sk:verify` reports code defects under a Code health section or dimension,
apart from findings against the spec.

Answer one question only: is the dropped-order defect reported as a code
health finding rather than as a failure of the spec?

PASS if the dropped-order (or off-by-one) finding appears under a Code health
heading or dimension, or is explicitly described as a defect no requirement or
scenario covers.

FAIL if the defect is not reported at all, if it appears only as a
requirement, scenario or task that is missing, unimplemented or failing, or if
the report says the requirement or either of its two scenarios is not
implemented.

Ignore everything else about the report: other findings, severities, IDs,
wording and layout.
