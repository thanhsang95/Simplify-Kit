---
# Without this section /sk:continue would count design as not done and write a
# design.md for a change that was already planned in one step.
type: regex
pattern: '## Design[\s\S]*Skipped'
target:
  source: file
  path: sk/changes/us-12345-field-selector/proposal.md
---
