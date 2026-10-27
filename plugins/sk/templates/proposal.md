# <Work item id | req> — <Work item title | short title of the request>

**Work item:** <full URL | none — direct request>
**Type / State:** <User Story | Bug | Task> / <state>
**AC source:** <work item | related AB#<id>, confirmed | parent AB#<id>, narrowed | test cases AB#<id>[, AB#<id>], confirmed | user, in conversation | none yet>
**Symptom:** <Bug only: the actual result from the repro steps, one line>

<!--
`/sk:continue` reads the AC source line to know where the criteria live, and
refuses to write a spec delta while it says "none yet". Only when the source is
"user, in conversation" is there a section below holding the text itself;
"test cases …, confirmed" reads the quoted steps under ## Test cases.
Drop the Type / State line for a direct request — there is no work item to have one.
Drop the Symptom line unless the work item is a Bug (or a Task under one).
Write "none stated" when the repro steps give no actual result.
/sk:apply's first test must fail with it, and apply never reads Azure DevOps.
-->

## Request

<!--
Only for a direct request (no work item): the request exactly as the user gave
it. Nothing else holds it, so this is the only copy. Drop otherwise.
-->

<The request, verbatim.>

## Summary

<Two or three sentences. What this change is, in the reader's terms.>

<!--
This file is a pointer, not a restatement. The why and the what already live on
the board; a second copy here only gives the two somewhere to drift apart.
What belongs here is what the board does NOT hold: how the criteria were read,
what was assumed, and what is still open. A direct request has no board, which
is why its text is kept under ## Request above.
-->

## Capabilities

**Added:** <capability> — <one line>
**Modified:** <capability> — <one line>

## How the acceptance criteria were read

<!--
Only when the mapping was not obvious — grouped bullets mapping to
requirements is obvious and needs nothing here. Prose that you split yourself
does: record the split, so a reviewer can disagree with it directly instead of
reconstructing it.
-->

<How AC were grouped into requirements and scenarios, when it needed judgement.>

## Acceptance criteria not on the board

<!-- Only when the AC source is "user, in conversation". Drop otherwise. -->

<The criteria as the user gave them.>

## Repro steps

<!--
Bug only (or a Task under one): the repro steps' steps and expected result,
HTML stripped, verbatim. An exception to "pointer, not restatement":
/sk:apply never reads Azure DevOps, and its first test is built from these
steps; /sk:continue reads them when the AC source is not the work item.
The actual result goes on the Symptom line, not here. Drop otherwise.
-->

<The steps and the expected result, verbatim.>

## Test cases

<!--
Every test case read through a Tested By link. Drop when there are none.
Quote each step as decoded: /sk:continue takes a confirmed step's action as
the WHEN and its expected result as the THEN, and /sk:apply uses the steps as
test setup; neither re-fetches the test case. A test case is evidence, not
acceptance criteria: a step's expected result becomes a criterion only when a
person confirms it.
  covered                — the criteria already say this
  pins <what>            — the exact value a criterion leaves open (a message, a number)
  open                   — not in the criteria, or contradicts them; also listed under Gaps
  confirmed as criterion — a person confirmed it as a criterion
-->

<N more linked test cases were not read (limit 10).> <!-- only when there were more -->

- AB#<id> <title>
  - "<action>" → "<expected result>" — covered | pins <what> | open | confirmed as criterion

## Comments that override the description

<!-- Drop this section when there are none. -->

- <comment author, date>: <what it changed, and what it overrode>

## Out of scope

<!--
What this change deliberately does NOT do, and where that was decided. Not a
Gap: a Gap is not known yet; this is known and excluded. Only what a source
actually ruled out — never a list of everything the work item does not
mention. /sk:continue writes no scenario for it, /sk:apply stops before
building it, /sk:verify reports it if the code does it anyway, /sk:pr lists
it. Drop when there is nothing.
-->

- <what is not done> — Source: <comment, author, date | AC: "<quoted words>" | user, G<n> | test case AB#<id> step <n>, ruled out> — confirmed | unconfirmed

## Assumptions

- <a decision settled while reading the work item, and what it rests on> — confirmed | unconfirmed
- Q<n> — <the concrete value used>. Source: <where it came from>. Verifiable: yes|no.

<!--
`confirmed`: /sk:propose asked and the user answered. `unconfirmed`: nobody
could answer, so the recommended answer was written down; a reviewer should
look at these first. Q<n> entries are /sk:continue's and carry their own
provenance, so they take neither word.
-->


## Open questions

<!--
One entry per unresolved decidable token — see reference/conventions.md
("Ambiguous acceptance criteria"). The criterion is covered; the value isn't
pinned down. Different from a Gap, which the AC doesn't cover at all.
-->

- Q<n> — <the question, and the marker's location in the delta>

## Gaps

<!--
Criteria that could not be turned into observable behaviour, and questions
that need an answer. Empty is a legitimate answer; inventing a scenario to
close a gap is not.
-->

- <the criterion, and what is unclear about it>

## Design

<!--
Written by /sk:continue only when it decides no design.md is needed, so the next
invocation knows that artifact is done. Drop when design.md exists.
-->

Skipped — <the reason>.

## Impact

- `<path>` — <what changes there>
