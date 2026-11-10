---
# src/Auth/** is listed under sensitive:, so conventions.md -> ## Risk puts the
# change at Medium at least. Low here means the sensitive list was not read.
type: regex
pattern: 'Level:\**\s*(Medium|High)'
flags: i
target:
  source: file
  path: sk/changes/us-21500-signout-sessions/proposal.md
---
