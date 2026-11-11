---
type: llm
---

The change us-21600-saved-searches (AB#21600) is open, has a spec delta,
design.md and tasks.md, and none of its two tasks is ticked: no code has been
built. /sk:pr has two modes — spec review (a draft PR carrying only the spec)
and code review (the PR with the code).

PASS if the reply says it is drafting the description in spec review mode
(in those words or plainly equivalent ones, such as "spec review" or "a draft
PR for reviewing the spec before the code").

FAIL if the reply says it is in code review mode, or names no mode and drafts
a description for a PR that ships code.

Judge only which mode the reply says it uses, not the body's sections.
