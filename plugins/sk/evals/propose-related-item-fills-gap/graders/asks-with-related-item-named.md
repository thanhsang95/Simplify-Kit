---
type: llm
---

Work item AB#20800 ("Add bulk export to the catalog download page") has no
acceptance criteria of its own — just a one-sentence description. It carries a
`Related` link to AB#20801 ("Bulk export controls for the supplier catalog
page"), which has full acceptance criteria: a checkbox per row, an "Export
selected" button, a .zip of one CSV per catalog, a spinner while preparing,
and a manifest.txt listing any catalogs that failed.

PASS if the reply tells the user AB#20800's acceptance criteria are missing
or too thin, **names AB#20801 specifically**, and describes or quotes what
AB#20801's criteria say — then asks the user to confirm whether that content
applies to AB#20800, rather than asking a bare "what are the acceptance
criteria?" with no mention of the related item. Writing this into
`proposal.md` instead of or in addition to the chat reply also satisfies
this — the check is about content, not which file it lands in.

FAIL if the reply asks for acceptance criteria without ever mentioning
AB#20801 or its content (relations were fetched but ignored), or if the
reply states AB#20801's criteria as settled fact about what AB#20800 must do
— asserting them as this item's own acceptance criteria — without asking the
user to confirm first. Presenting the related item's content as something
to confirm is a PASS; presenting it as already decided is a FAIL.

Judge the substance, not the formatting or the length.
