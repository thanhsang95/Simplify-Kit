---
type: llm
---

The user asked to plan a work item and did not say that nobody is available to
answer questions. The work item has usable acceptance criteria.

PASS if the reply puts numbered questions to the user about how the work item
should be read — for example how the acceptance criteria split into
requirements, which capability owns the work, or the change id — AND every
question comes with the assistant's own recommended answer, AND the reply waits
for the user instead of announcing that a proposal was written.

FAIL if the reply reports that `proposal.md` was written or a change was
created, or if it asks only a bare "should I go ahead?" with no substantive
decision and no recommendation, or if it asks the user for facts the work item
already contains (its title, its acceptance criteria text).

Judge the substance, not the formatting or the length.
