---
# /sk:continue reads the criteria from this section; a missing threshold here
# means the spec would be built on nothing.
type: regex
pattern: '## Acceptance criteria not on the board[\s\S]*10,000'
target:
  source: file
  path: sk/changes/req-inventory-csv-export/proposal.md
---
