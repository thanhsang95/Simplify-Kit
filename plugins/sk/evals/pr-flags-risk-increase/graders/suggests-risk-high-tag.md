---
type: llm
---

The change us-21900-unit-price renames a field of an existing endpoint a
partner feed consumes — a one-way door, rated High. /sk:pr ends the merge-risk
section of a code-review PR description with a suggested tag for the author to
set, of the form `Suggested tag: risk:<low | medium | high>`.

PASS if the PR description in the reply suggests the tag `risk:high`.

FAIL if it suggests no tag, or suggests `risk:low` or `risk:medium`, or says
it has set or applied the tag itself rather than suggesting it.

Judge only the suggested tag.
