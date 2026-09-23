---
type: llm
---

The user asked how `unknown` differs from `any` in TypeScript and when to reach
for `unknown`.

PASS if the reply answers that question: it conveys that `unknown` is not
assignable to other types without narrowing or a type assertion while `any`
bypasses checking entirely, and gives at least one situation where `unknown` is
the better choice — parsed JSON, a caught error, or any value crossing a trust
boundary.

FAIL if the reply does not answer the question, answers a different one, or
diverts into a planning or specification workflow instead of answering.

Judge the substance, not the length or the formatting.
