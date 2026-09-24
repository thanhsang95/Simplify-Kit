---
# The two undecided criteria (retry count, size threshold) should leave the
# open-question marker in the delta. If neither scenario carries it, the
# ambiguity was either missed or silently resolved with an invented value.
type: regex
pattern: '\[\[OPEN:Q\d+\]\]'
target:
  source: file
  path: sk/changes/us-31200-csv-export/specs/csv-export/spec.md
---
