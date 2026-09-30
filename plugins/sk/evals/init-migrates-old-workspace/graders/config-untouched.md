---
# The sentinel comment is lost if config.yaml is regenerated or reflowed.
type: regex
pattern: 'KEEP-ME'
target:
  source: file
  path: sk/config.yaml
---
