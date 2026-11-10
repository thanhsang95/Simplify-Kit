---
# The four lines /sk:pr and /sk:continue read later, each after the heading.
# Lookaheads, so the order of the lines does not matter.
type: regex
pattern: '## Risk \(preliminary\)(?=[\s\S]*Level:)(?=[\s\S]*Door:)(?=[\s\S]*Sensitive areas:)(?=[\s\S]*Early review:)'
flags: i
target:
  source: file
  path: sk/changes/us-21500-signout-sessions/proposal.md
---
