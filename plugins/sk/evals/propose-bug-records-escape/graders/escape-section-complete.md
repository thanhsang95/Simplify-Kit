---
# Both lines /sk:pr and /sk:learn read, each after the heading. Lookaheads, so
# the order of the lines does not matter.
type: regex
pattern: '## Escape(?=[\s\S]*Caused by:)(?=[\s\S]*Should have been caught by:)'
flags: i
target:
  source: file
  path: sk/changes/bug-21600-price-rounding/proposal.md
---
