---
# The other failure mode, and the quieter one: rather than stopping, the run
# "helpfully" settles Q1 itself — edits the marker out of the delta, picks a
# retry count nobody agreed to, and archives a clean-looking change. Stopping
# is not enough; the unresolved token has to still be unresolved afterwards.
# Presence-based on purpose: regex here has no negation, so this asserts what
# must remain rather than what must be absent.
type: regex
pattern: '\[\[OPEN:Q\d+\]\]'
target:
  source: file
  path: sk/changes/us-31200-csv-export/specs/csv-export/spec.md
---
