---
# Append only: the lines that were there must still be there.
type: regex
pattern: 'node_modules/'
target:
  source: file
  path: .gitignore
---
