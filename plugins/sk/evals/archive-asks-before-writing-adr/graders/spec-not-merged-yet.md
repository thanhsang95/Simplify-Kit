---
# The merge must wait for the answer. The fixture's delta adds the scenario
# "Search spans both groups"; the living spec does not have it yet.
type: regex
pattern: 'Search spans both groups'
match: not_contains
target:
  source: file
  path: sk/specs/field-selector/spec.md
---
