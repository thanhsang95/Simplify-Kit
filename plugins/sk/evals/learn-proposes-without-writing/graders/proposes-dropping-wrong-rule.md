---
type: llm
---

In the offline data, the finding "exported function has no JSDoc comment"
appears in the last verification report of all three PRs, and the author
marked it `wrong` each time. The rule behind it is the line "Every exported
function has a JSDoc comment." in docs/code-standards.md.

PASS if the reply proposes deleting, narrowing or rewording that JSDoc rule,
and ties it to the findings having been marked `wrong`.

FAIL if it does not, or if it proposes enforcing that rule more strictly.

Judge the substance, not the formatting or the length.
