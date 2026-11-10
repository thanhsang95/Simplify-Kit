---
# Step 5 ends the appended section with `Code standards: <path>`, the doc
# Step 2 put in `context`, so /code-review (which reads only CLAUDE.md) judges
# by the rules /sk:verify uses. The fixture's only standards doc is
# docs/code-standards.md. Same line, any quoting or leading ./ around the path.
type: regex
pattern: 'Code standards:[^\n]*docs/code-standards\.md'
target:
  source: file
  path: CLAUDE.md
---
