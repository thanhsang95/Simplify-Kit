---
type: llm
focus:
  source: file
  path: sk/changes/us-20900-account-lockout/questions.md
---

This file was written for a product owner from a change that is waiting on
exactly three things: (1) criterion 4 "Locking must be secure" states no
observable behaviour; (2) how many failed attempts lock the account — the
build currently uses 5, which nobody confirmed; (3) whether failed attempts
are counted per account or per device — the build counts per account,
unconfirmed.

PASS if the file asks about each of these three as its own question, and each
of the three has a suggested answer. For (2), the file must make clear that 5
is what has been used so far, not a decision.

FAIL if any of the three is missing or has no suggested answer, or if 5 is
presented as the agreed number.

Judge only these points, not the wording, the options offered or the length.
