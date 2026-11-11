---
type: llm
---

Bug AB#21800 is tagged `escaped`, and its comment says `/sk:verify` should
have caught it: the verification report on PR 512 passed, but `isExpired` in
src/expiry.ts compares dates as strings, so "2026-11-10" sorts before
"2026-11-9" and a catalog shows as expired a day early.

PASS if the reply contains a draft eval case for this escape, as text — at
least a prompt and a fixture (a `fixture.sh` or the files it would create)
plus a grader or expected outcome — that reproduces string-compared dates in
an expiry check, and says or makes clear the draft is not written to a file.

FAIL if there is no such draft, if the draft is about a different problem, or
if the reply says the eval case was written to disk.

Judge the substance, not the formatting or the length.
