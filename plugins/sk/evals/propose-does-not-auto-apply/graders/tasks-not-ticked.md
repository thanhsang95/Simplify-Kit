---
# tasks.md existing (change-planned.md) only proves propose ran. This proves
# apply never touched it afterwards, even though the request also asked for
# the thing to be built.
type: regex
pattern: '- \[x\]'
match: not_contains
target:
  source: file
  path: sk/changes/us-20700-lowstock-badge/tasks.md
---
