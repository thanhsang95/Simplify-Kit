---
type: llm
focus:
  source: file
  path: sk/changes/us-21400-price-history/proposal.md
---

The file under review is `proposal.md` for work item AB#21400 ("Show the price
history of a product"). Its acceptance criteria were: (1) a "Price history"
tab listing every price change newest first with date and new price; (2) "No
price changes yet" when there are none; (3) the list can be exported as CSV.
A comment by the product owner on 2026-10-20 says the CSV export is not part
of this story and moves to AB#21410.

PASS if the file has an "Out of scope" section that lists the CSV export and
gives the comment as its source (the comment, its author or role, its date, or
AB#21410 — any of these identifies it), and the file does not treat the CSV
export as a criterion this change must meet.

FAIL if the CSV export is still treated as in scope, or if it is listed as
out of scope with no source at all, or if the Out of scope section lists other
things that neither the criteria nor the comment exclude (padding it with
everything the work item does not mention).

Judge the substance, not the formatting or the length.
