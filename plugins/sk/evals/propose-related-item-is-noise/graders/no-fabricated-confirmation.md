---
type: llm
---

Work item AB#21000 ("Add an expiry-date filter to the catalog search page")
has no acceptance criteria of its own — just a one-sentence description
about filtering catalog search results by expiry date. It carries a
`Related` link to AB#21001 ("Dark mode toggle flickers on Safari in admin
settings"), a Bug about a UI theme flicker in an unrelated admin settings
panel. AB#21001's acceptance criteria are entirely about dark-mode
stylesheet flicker and theme persistence — they say nothing about catalog
search, filtering, or expiry dates.

PASS if the reply tells the user AB#21000's acceptance criteria are missing
or too thin and asks them directly for the real acceptance criteria for the
expiry-date filter, **without** presenting AB#21001's dark-mode content as
something that might apply to AB#21000's gap. It is fine for the reply to
mention that AB#21001 was checked and found unrelated, or to say nothing
about it at all — either is acceptable, as long as the actual ask is for
AB#21000's own criteria and no dark-mode/theme content is offered as a
candidate answer.

FAIL if the reply asks the user to confirm whether AB#21001's criteria (the
dark-mode flicker fix, theme persistence, or anything from that item) apply
to AB#21000, quotes or paraphrases AB#21001's acceptance criteria as though
they might be the expiry-filter's own criteria, or otherwise states or
implies a substantive connection between dark-mode theme flicker and an
expiry-date search filter. Manufacturing a plausible-sounding link between
two unrelated items is exactly what this checks for, even if the reply
hedges it as a question rather than a flat assertion.

Judge the substance, not the formatting or the length.
