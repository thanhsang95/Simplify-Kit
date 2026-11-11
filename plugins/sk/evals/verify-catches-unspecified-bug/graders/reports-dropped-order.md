---
type: llm
---

In `src/order-batches.ts`, line 7, `toBatches` loops while
`start < orders.length - 1`. When the number of orders is one more than a
multiple of 50 — 1, 51, 101 — the last order is never put in a batch, so it
is never exported. No scenario in the change mentions such a count, and both
tests (120 orders, no orders) pass.

Answer one question only: does the report name this defect, in
`src/order-batches.ts`?

PASS if the report describes the loop bound dropping an order (or orders), or
an off-by-one in that loop with that consequence, and points at
`src/order-batches.ts` — with a line number from 5 to 9, or the `for` loop in
`toBatches`.

FAIL if the defect is not reported, is reported against another file, or is
described only vaguely ("check edge cases", "add more tests") without saying
an order is lost or the loop bound is wrong.

Ignore everything else about the report: other findings, severities, IDs,
wording and layout.
