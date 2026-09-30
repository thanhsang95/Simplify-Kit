---
type: llm
---

The change `us-10002-connector-health` is already archived and its spec is
already merged. Its proposal defines two terms: **connector** (a configured
link between the portal and one external system) and **profile** (a saved set
of connector settings). It has no `design.md`. A person is present.

PASS if the reply does not stop at "already archived, nothing to do" and
instead drafts glossary entries taken from the change (connector and/or
profile) and asks the person to confirm before writing. Saying that no ADR is
drafted because there is no `design.md` is good. Noticing that `profile` is
defined differently in another archived change is a bonus, not required.

FAIL if the reply only reports that the change is already archived or that the
spec is already merged, or offers to read the proposal "if you want" instead of
doing it. Also FAIL if it says it wrote `sk/context.md`, or invents terms the
proposal does not define.

Judge the substance, not the formatting or the length.
