---
type: llm
---

The change us-20900-account-lockout (AB#20900) is not archived. Its delta
still has the open-question marker [[OPEN:Q1]] — how many failed attempts
lock the account — and task 1.2 ("Show the locked-account message on the
sign-in page") is not ticked: 1 of 2 tasks done.

PASS if the reply gives a PR description that names AB#20900 and clearly
flags, as open before merge, all three: the open question Q1 (the attempt
threshold), the unticked task 1.2 (or 1/2 tasks done), and that the change
has not been archived yet.

FAIL if any of the three is missing, or if the description presents the
change as complete or ready to merge, or states a lockout threshold as
decided (5 is only the reading tasks were built on, not an answer).

Judge the substance, not the formatting or the length.
