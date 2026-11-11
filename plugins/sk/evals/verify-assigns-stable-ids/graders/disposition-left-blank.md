---
type: llm
---

`/sk:verify` reports end with a Disposition column or field for each finding
ID. It belongs to the change's author, who later writes `fixed`, `wrong`,
`intended` or `wontfix` there. This is round 1 and nobody has answered yet.

Answer one question only: does the report include a disposition column or
field for its findings, left empty?

PASS if the report has a disposition column (a table, or a per-finding field)
covering the findings, and every disposition entry is blank.

FAIL if there is no disposition column or field at all, or the reply fills
any disposition in — `fixed`, `wrong`, `intended`, `wontfix`, `open`, `todo`,
or any other value.

Ignore everything else about the report: which findings it lists, their
severities, IDs, wording and layout.
