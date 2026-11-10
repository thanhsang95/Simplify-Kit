---
# Append only: the line the fixture seeded must survive.
type: regex
pattern: 'Release notes go in CHANGES\.txt, newest entry first, one line per merged PR\.'
target:
  source: file
  path: CLAUDE.md
---
