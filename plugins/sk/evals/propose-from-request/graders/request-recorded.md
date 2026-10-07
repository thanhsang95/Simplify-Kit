---
# No board holds a direct request, so proposal.md must: the only copy.
type: regex
pattern: '## Request[\s\S]*CSV export to the inventory report'
target:
  source: file
  path: sk/changes/req-inventory-csv-export/proposal.md
---
