---
# The change adds a public interface (attributes become selectable next to
# standard fields), so continue's design rule requires design.md with the
# interface under ## Contracts — the place a person reviews it before
# /sk:apply builds and tests against it. A Skipped note here is a miss.
type: regex
pattern: '## Contracts'
target:
  source: file
  path: sk/changes/us-12345-field-selector/design.md
---
