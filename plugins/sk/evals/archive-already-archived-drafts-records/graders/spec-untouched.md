---
# Records mode never touches sk/specs/. The fixture's spec has exactly one
# requirement; a second "### Requirement:" would mean a merge ran.
type: regex
pattern: '(?:### Requirement:[\s\S]*){2}'
match: not_contains
target:
  source: file
  path: sk/specs/connector-auth/spec.md
---
