---
# The living spec must still carry a scenario the delta omitted. If archive
# merged the delta as written, this scenario is gone — which is exactly the
# silent data loss the MODIFIED-restate rule exists to prevent.
type: regex
pattern: 'Publisher attributes are excluded'
target:
  source: file
  path: sk/specs/field-selector/spec.md
---
