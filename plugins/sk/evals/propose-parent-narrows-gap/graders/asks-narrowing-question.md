---
type: llm
---

Work item AB#21200 ("Verify catalog sync results") is a User Story with an
empty description and no acceptance criteria field at all. It has no
`Related` link. Its only connected items are a Hierarchy-Reverse parent,
AB#21201 ("Migrate catalog sync to the new delivery pipeline"), a Feature
with a real description and full acceptance criteria about moving catalog
sync onto a new delivery pipeline, running it for every publisher account,
surfacing throughput/failure counts on a monitoring dashboard, retrying
failed jobs up to 3 times, and causing no publisher-visible change — and a
Hierarchy-Forward child, AB#21202, a Task that is only a deployment-config
checklist with no acceptance criteria of its own.

PASS if the reply tells the user AB#21200's acceptance criteria are missing,
**names AB#21201 specifically**, describes or quotes what AB#21201 is about
(the pipeline migration), and asks the user a narrowing question — what part
of that migration this story covers, or what should specifically be verified
for AB#21200 — rather than either (a) asking a bare "what are the acceptance
criteria?" with no mention of AB#21201, or (b) presenting AB#21201's
acceptance criteria wholesale as though they were already decided to be
AB#21200's own criteria. Writing this into `proposal.md` instead of or in
addition to the chat reply also satisfies this — the check is about content,
not which file it lands in. It is fine, and not required, for the reply to
also mention AB#21202.

FAIL if any of the following happens:
- The reply asks for acceptance criteria without ever mentioning AB#21201 or
  its content (the parent was fetched but ignored, or never fetched at all)
- The reply states AB#21201's acceptance criteria as settled fact about what
  AB#21200 must do — copying the migration's full criteria list (or most of
  it) onto AB#21200 as if confirmed, without first asking the user whether
  that scope, or which part of it, applies to this story
- The reply treats AB#21202 (the child Task's deployment checklist) as
  though it were AB#21200's acceptance criteria

Presenting AB#21201's content as context for a question the user must still
answer is a PASS; presenting it as already decided, or asking a bare
yes/no "does the parent's AC apply here" that would let the whole list
transfer wholesale with one word, is a FAIL — the point of this check is
that the question narrows scope, it does not just relocate the confirmation
from "what are the criteria" to "do you accept this list."

Judge the substance, not the formatting or the length.
