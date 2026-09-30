---
# A change that already has a spec delta is left alone: /sk:continue reads the
# AC source line only to write the delta.
type: regex
pattern: 'AC source'
match: not_contains
target:
  source: file
  path: sk/changes/us-12345-field-selector/proposal.md
---
