---
# Archived changes are recorded by the merged spec, sk/adr/ and sk/context.md,
# so the archive itself is kept out of git. The fixture has no .gitignore, so
# this also catches init failing to create one.
type: regex
pattern: 'sk/changes/archive/'
target:
  source: file
  path: .gitignore
---
