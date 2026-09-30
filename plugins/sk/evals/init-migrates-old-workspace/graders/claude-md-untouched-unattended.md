---
# Item 6 needs a person. Unattended, it is reported and not applied.
type: regex
pattern: '/sk:continue'
match: not_contains
target:
  source: file
  path: CLAUDE.md
---
