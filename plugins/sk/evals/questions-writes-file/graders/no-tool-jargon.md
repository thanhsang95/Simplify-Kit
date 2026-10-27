---
type: llm
focus:
  source: file
  path: sk/changes/us-20900-account-lockout/questions.md
---

This file is for a product owner who has never used the tool that produced it.

PASS if the questions themselves are written in plain product language. An
HTML comment such as `<!-- ref: Q1 -->` is allowed: it is a hidden reference,
not text the reader sees.

FAIL if the visible text contains the marker `[[OPEN:`, the word `SHALL`, a
file path, or the words "scenario", "delta" or "spec delta".

Judge only this.
