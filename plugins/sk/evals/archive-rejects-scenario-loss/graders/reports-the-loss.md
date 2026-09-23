---
type: llm
---

The living spec holds a requirement with three scenarios. The change's MODIFIED
delta restates the same requirement with only one of them. Merging it as written
would delete the other two.

PASS if the reply stops short of archiving and tells the user why: that the
delta's requirement carries fewer scenarios than the one in the spec, that
merging it would drop the missing scenarios, or that the delta needs to restate
the requirement in full. Naming the specific scenarios at risk is good but not
required. Offering to proceed once the user confirms is fine.

FAIL if the reply reports the change as archived, reports the spec as merged,
or treats the delta as acceptable as it stands. Also FAIL if it stops for an
unrelated reason it invented — an incomplete task list, a missing file — rather
than the scenario loss, since the tasks are all complete and the files are all
present.

Judge the substance, not the formatting.
