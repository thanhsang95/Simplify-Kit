---
type: llm
focus:
  source: file
  path: sk/changes/us-31200-csv-export/specs/csv-export/spec.md
---

The work item's acceptance criteria stated, in substance:

1. Clicking "Export CSV" generates a CSV containing every row currently
   visible after filters and search are applied — no more, no fewer.
2. The downloaded file is named `products-export-YYYY-MM-DD.csv`, using the
   current date in that exact format.
3. If the export request fails, the system retries automatically before
   giving up. No retry count or limit is stated anywhere in the work item.
4. When an export contains a very large number of rows, the system shows a
   progress indicator instead of blocking the UI. No numeric threshold for
   "very large" is stated anywhere in the work item.
5. Only users with the Catalog Manager role can trigger an export; the
   button is not shown to anyone else.

Criteria 1, 2 and 5 are fully pinned down by the source text — there is
nothing left to decide. Criteria 3 and 4 read as confident, complete
sentences but each leaves a number undecided (how many retries; how large is
"very large") that the work item never states anywhere.

PASS if the scenarios for criteria 1, 2 and 5 state their behaviour as
concrete, decided claims with no open-question marker and no invented
number standing in for one. AND at least one of criteria 3 or 4 has its
undecided number represented by an open-question marker placed inside the
THEN itself (not just mentioned in prose elsewhere), rather than by a
specific invented number (e.g. "after 3 retries", "more than 10,000 rows")
that the work item never gave. AND no scenario dodges the ambiguity by
writing a THEN so vague it asserts nothing checkable (e.g. "the system SHALL
retry appropriately" with no marker at all) — an unresolved number must
either carry the marker or the scenario must be absent from the spec, not be
smoothed over with vague wording.

FAIL if any of criteria 1, 2 or 5 carries an open-question marker (that is
over-marking — treating a decided criterion as if it were unresolved). Also
FAIL if both criteria 3 and 4 are given specific invented numbers with no
marker and no record that a number was assumed. Also FAIL if a scenario for
3 or 4 is vague prose with no decidable token and no marker, dodging the
ambiguity instead of naming it.

Judge the substance and placement of the marker, not the exact wording
around it.
