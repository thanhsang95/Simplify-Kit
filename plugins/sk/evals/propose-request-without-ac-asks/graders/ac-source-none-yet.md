---
# Unattended does not turn drafted criteria into the user's: "unconfirmed"
# is for readings, not for acceptance criteria nobody wrote.
type: regex
pattern: 'AC source:\*\*\s*none yet'
target:
  source: file
  path: sk/changes/req-faster-inventory-report/proposal.md
---
