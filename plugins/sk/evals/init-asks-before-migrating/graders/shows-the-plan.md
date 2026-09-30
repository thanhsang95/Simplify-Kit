---
type: llm
---

The workspace was made by an older SimplifyKit. It needs: a `.gitignore` entry
for `sk/changes/archive/`; a `## Design` "Skipped" marker on
`us-12345-field-selector`; an `**AC source:** none yet` line on
`us-20600-catalog-download`; and, report-only, the archived change
`us-10000-old-change` (which has a design.md) and a `CLAUDE.md` line for
`/sk:continue`. A person is present.

PASS if the reply lists what it found, says concretely what it would add to
which file, and asks the person to confirm before applying, without having
applied anything. Listing the archived-change item as informational is fine.

FAIL if the reply says it already made the changes, says the workspace is
already up to date, or asks only a bare "should I go ahead?" without showing
what it found.

Judge the substance, not the formatting or the length.
