---
# The cut export must sit under ## Out of scope, not only under the comments
# section: that is the list continue, apply, verify and pr read.
type: regex
pattern: '## Out of scope[^#]*CSV'
flags: i
target:
  source: file
  path: sk/changes/us-21400-price-history/proposal.md
---
