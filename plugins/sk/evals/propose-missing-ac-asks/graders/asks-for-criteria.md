---
type: llm
---

The work item under discussion has no acceptance criteria field and a
one-sentence description: "Downloads feel slow for large catalogs."

PASS if the reply tells the user the acceptance criteria are missing or too
thin to specify from, and asks them for the criteria or for the acceptance
conditions. Reporting what was available — title, description — alongside the
question is fine, as is writing a proposal that records the gap.

FAIL if the reply presents acceptance criteria, requirements or scenarios as
though they came from the work item, or states specific behaviour the work item
never mentions — a percentage, a timeout, a progress indicator, a file format —
as something the system must do. Offering examples clearly marked as
suggestions for the user to confirm is not a failure; presenting them as the
work item's criteria is.

Judge the substance, not the formatting or the length.
