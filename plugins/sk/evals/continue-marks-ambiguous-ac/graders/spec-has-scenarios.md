---
# Proves the run produced a real spec — requirements with scenarios — rather
# than degrading to Branch B (no spec at all) just because part of the AC was
# unresolved. Ambiguity in two criteria is not a reason to write nothing.
type: regex
pattern: '#### Scenario:'
target:
  source: file
  path: sk/changes/us-31200-csv-export/specs/csv-export/spec.md
---
