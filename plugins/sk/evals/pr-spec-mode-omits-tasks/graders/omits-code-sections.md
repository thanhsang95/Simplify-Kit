---
type: llm
---

The change us-21600-saved-searches has no ticked task, so its PR description
is for a draft PR that carries only the spec. That body must not have any of
these four sections: **Tasks** (task progress such as "0/2 done"),
**Evidence**, **Open before merge**, **Merge danger**.

PASS if the PR description in the reply has none of those four sections.

FAIL if the description has any one of them as a section or heading — a
"Merge danger" or "Tasks" heading counts even when its content is short.
A section headed "Risk (preliminary)" is allowed and is not "Merge danger".

Judge only which sections the description has, not their wording.
