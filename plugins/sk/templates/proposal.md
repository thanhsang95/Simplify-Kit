# <Work item id | req> — <Work item title | short title of the request>

**Work item:** <full URL | none — direct request>
**Type / State:** <User Story | Bug | Task> / <state>
**AC source:** <work item | related AB#<id>, confirmed | parent AB#<id>, narrowed | user, in conversation | none yet>

<!--
`/sk:continue` reads the AC source line to know where the criteria live, and
refuses to write a spec delta while it says "none yet". Only when the source is
"user, in conversation" is there a section below holding the text itself.
Drop the Type / State line for a direct request — there is no work item to have one.
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

## Comments that override the description

<!-- Drop this section when there are none. -->

- <comment author, date>: <what it changed, and what it overrode>

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
