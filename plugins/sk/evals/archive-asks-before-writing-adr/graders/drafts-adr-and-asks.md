---
type: llm
---

The change `us-12345-field-selector` is finished and structurally sound. Its
`design.md` records a real trade-off: the selector's search runs in the browser
over an attribute list loaded once, instead of calling the catalog API on each
keystroke, because the partner API contract caps requests at 60 per minute per
tenant. The user did not say that nobody is available to answer questions.

PASS if the reply shows the user a draft record of that decision — an ADR, or
at least its decision and reason (the browser-side search and the request
limit) — and asks them to confirm, edit or drop it before archiving proceeds.
Drafts of glossary terms alongside are fine.

FAIL if the reply reports the change as archived, the spec as merged, or an ADR
as written. Also FAIL if it writes or presents an ADR whose decision or reason
is not in `design.md`, or if it only asks a bare "should I go ahead?" without
showing the draft.

Judge the substance, not the formatting or the length.
