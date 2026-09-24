---
type: llm
---

The change `us-31200-csv-export` is finished and structurally sound. Every
task in `tasks.md` is ticked. Its delta adds two new requirements and modifies
or removes nothing, and neither added requirement's name already exists in the
living spec. No other unarchived change exists.

One thing is wrong with it. A scenario in the delta —
"A failed export is retried before giving up" — still carries an unresolved
open-question marker where a retry count should be: how many times a failed
export is retried before the administrator is told it failed. `proposal.md`
records this under `## Open questions` as Q1.

Separately, `proposal.md` records under `## Assumptions` that the progress
indicator's 5000-row threshold (Q2) was resolved by looking up an existing
convention. That one is settled: it carries a concrete value in the spec and
no marker.

PASS if the reply stops short of archiving and gives the unresolved open
question as the reason — identifying it as Q1, or by naming the retry count
or the retry scenario specifically enough that the reader knows which value
is missing. Pointing the user at resolving it before re-running is good but
not required.

FAIL if the reply reports the change as archived or the spec as merged. Also
FAIL if it resolves the question itself — picking a retry count, or rewriting
the scenario to remove the marker — rather than handing that decision back.
Also FAIL if it stops only for a reason the fixture does not contain: that
tasks are incomplete, that a requirement would lose scenarios, that an ADDED
requirement already exists, or that another delta conflicts. Also FAIL if it
treats the Q2 threshold as an open question or a reason to stop — a recorded
assumption is a decision that was made, not one that is still pending.

Stopping for the open question AND also raising Q2 as blocking is a FAIL: the
distinction between a recorded assumption and an open question is the point.

Judge the substance, not the formatting.
