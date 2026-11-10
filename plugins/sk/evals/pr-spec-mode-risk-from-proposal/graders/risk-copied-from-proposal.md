---
type: llm
---

The change us-21700-idle-timeout has no tasks.md yet, so its PR description is
for a draft PR that carries only the spec. Its proposal.md says, under
"Risk (preliminary)": Level Medium (unconfirmed); Door two-way — only adds a
check, reverting the commit restores sessions that never time out; Sensitive
areas src/Auth/**; Early review yes.

PASS if the PR description in the reply has a risk section that gives the
level as Medium and the door as two-way, matching the proposal.

FAIL if the description has no risk section, or gives a different level or
door than the proposal does (for example Low, or High, or one-way).

Judge only the level and the door, not the formatting or the length.
