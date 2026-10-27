---
# /sk:apply never reads Azure DevOps and builds its first test from these steps.
type: regex
pattern: '## Repro steps[\s\S]*Hide expired'
target:
  source: file
  path: sk/changes/bug-21100-hide-expired/proposal.md
---
