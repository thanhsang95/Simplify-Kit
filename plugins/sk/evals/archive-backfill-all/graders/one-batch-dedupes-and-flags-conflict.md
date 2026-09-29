---
type: llm
---

Three changes are archived. `us-10001-connector-auth` and
`us-10002-connector-health` both define **connector** in the same words.
`us-10002-connector-health` defines **profile** as a saved set of connector
settings, while `us-10003-user-profiles` defines **profile** as a user's
display name and avatar - a conflict. Only `us-10001-connector-auth` has a
`design.md`, recording that connector credentials are stored encrypted on the
server and never sent to the browser. A person is present.

PASS if the reply presents ONE draft covering all three changes in which
connector appears once (not twice), AND raises the two conflicting definitions
of profile as a question for the person rather than choosing one, AND drafts an
ADR for the server-side credential decision from `us-10001-connector-auth`,
AND asks the person to confirm before anything is written, without having
written anything.

FAIL if it asks about each change separately in turn, lists connector twice as
separate entries, silently picks one meaning of profile, drafts an ADR for a
change with no `design.md`, or says it already wrote `sk/context.md` or an ADR.

Judge the substance, not the formatting or the length.
