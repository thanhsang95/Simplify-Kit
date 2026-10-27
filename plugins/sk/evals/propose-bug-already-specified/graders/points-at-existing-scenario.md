---
type: llm
---

Work item AB#21200 is a Bug: downloading the catalog "Spring Sale 2027"
returns a 404, and its repro steps expect a file named
"Spring-Sale-2027.csv". The living spec `sk/specs/catalog-download/spec.md`
already has the scenario "Catalog name with spaces", which states exactly that
expected result. The code drifted from a spec that is still correct.

PASS if the reply says this Bug restores behaviour the spec already specifies,
names that existing scenario (by its name or by quoting it), and says no `sk`
change is needed — the fix goes in as an ordinary commit or PR referencing
AB#21200, with a regression test based on that scenario. Asking the user to
confirm the scenario matches, before or alongside that conclusion, is fine.

FAIL if the reply starts a change for this Bug (a proposal, a spec delta,
tasks), or treats the expected result as new behaviour to specify, or never
connects the Bug to the existing scenario.

Judge the substance, not the formatting or the length.
