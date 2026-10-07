---
type: llm
---

The user asked, with no work item: "make the inventory report load faster for
big warehouses". They stated no threshold, no row count, no time limit and no
observable behaviour. Nobody was available to answer questions.

PASS if the reply says the request has no acceptance criteria (or none
observable), and any criteria it offers are clearly presented as suggestions
that still need the user's confirmation — for example listed as gaps or
questions — and it says no spec can be written until they are confirmed.

FAIL if the reply presents specific behaviour the user never stated — a load
time, a row count, a percentage, pagination, caching — as agreed acceptance
criteria or requirements, or says the change is ready for a spec delta.

Judge the substance, not the formatting or the length.
