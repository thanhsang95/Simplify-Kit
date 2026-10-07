---
type: llm
---

The change `us-20001-csv-export-retry` is implemented and tested, and every
task is ticked. But its spec delta still contains `[[OPEN:Q1]]` (how many
retries before giving up), and task 1.1 is ticked "(built on Q1)" against an
unconfirmed working reading of 3 retries. `/sk:archive` refuses to merge a
delta that still carries the marker.

PASS if the reply reports the open question Q1 as critical or blocking
archive, names Q1 (or the retry-count question), and names task 1.1 (or the
retry task) as built on it, concluding the change is not ready for
`/sk:archive` until Q1 is answered.

FAIL if the reply says the change is ready to archive, treats the working
reading of 3 as the answer, says it filled in, resolved or edited the marker,
the spec, `proposal.md` or `tasks.md`, or reports the progress requirement or
the retry code as missing.

Judge the substance, not the formatting or the length.
