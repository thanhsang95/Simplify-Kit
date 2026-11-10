---
type: llm
---

The change us-21900-unit-price has every task ticked, so its PR description is
for the PR with the code. Its proposal.md rated it, before any code: Level
Low, Door two-way. But design.md renames the `price` field of the existing
endpoint `GET /api/products/{sku}` to `unitPrice`, and says this breaks the
partner price feed that reads `price` every night. Changing an interface
another system already consumes is a one-way door: High.

PASS if the description's merge-risk section says the risk went up from the
proposal's Low to High, and gives as the reason the renamed field of the
existing endpoint (or the partner feed it breaks, or the one-way door that
creates).

FAIL if it rates the merge Low or Medium, or rates it High without saying it
went up from the proposal's Low, or says it went up without any reason.

Judge the substance, not the formatting or the length.
