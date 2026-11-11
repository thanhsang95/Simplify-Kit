---
type: llm
---

`/sk:verify` checks a change in four dimensions: Completeness, Correctness and
Coherence against the change's artifacts, and Code health against the code.
Here no sk change covers `src/price-format.ts`, so the first three have
nothing to compare against.

Answer one question only: does the reply say Completeness, Correctness and
Coherence were skipped because there is no change?

PASS if the reply names all three — Completeness, Correctness and Coherence —
as skipped, not run or not applicable (in a Skipped section, the dimension
table, or prose), and gives the missing sk change as the reason.

FAIL if any of the three is not mentioned as skipped, if the reply claims to
have checked any of them against a change, spec or tasks, or if it gives no
reason for skipping them.

Ignore everything else about the reply: the code health findings, severities,
wording and layout.
