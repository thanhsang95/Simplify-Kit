---
type: llm
---

The change us-12345-field-selector is already archived. Its artifacts say:
work item AB#12345 "Add product attributes to the field selector"; the delta
ADDS "Field selector offers system attributes" (2 scenarios) and MODIFIES
"Field selector search" (search now also filters attributes); design.md has
one contract, `listSelectableFields()`; tasks are 3/3 done. Nothing in the
artifacts says any test was run.

PASS if the reply gives a PR description that: links or names AB#12345;
names both requirements and says which is added and which is modified (with
what changed for the modified one); gives the task progress as all done
(3/3); and has a merge-risk assessment that says why (for example a two-way
door because it only adds behaviour and one exported function, with
administrators using the field selector as the blast radius).

FAIL if the description claims tests passed, were run, or that the change was
reviewed or verified; or invents links, reviewers or numbers the artifacts do
not contain; or calls the change safe or low-risk with no reason; or omits the
modified requirement. Leaving an "Evidence" section for the author to fill in
is fine and expected.

Judge the substance, not the formatting or the length.
