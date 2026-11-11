---
# A PR id ("PR 123", "#123", "!123") or a change id ("us-…", "bug-…") on the
# Caused by line is one the model supplied: the fixture names none. A G<n>
# question reference on the line is fine, so not every digit fails.
type: regex
pattern: 'Caused by:[^\n]*(?:PR\s*#?\s*\d|[#!]\d|\b(?:us|bug)-\d)'
flags: i
match: not_contains
target:
  source: file
  path: sk/changes/bug-21600-price-rounding/proposal.md
---
