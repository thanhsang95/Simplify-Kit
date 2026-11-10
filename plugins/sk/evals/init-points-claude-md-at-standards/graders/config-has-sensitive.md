---
# The template carries `sensitive: []` for the team to fill; a fresh init
# copies it, so /sk:pr has the key to read.
type: regex
pattern: 'sensitive:'
target:
  source: file
  path: sk/config.yaml
---
