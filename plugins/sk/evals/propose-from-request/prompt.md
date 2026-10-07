---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

sk propose: Add a CSV export to the inventory report. This has no work item.

Acceptance criteria:
1. The inventory report page shows an "Export CSV" button.
2. Clicking it downloads a CSV with one row per inventory item and the same columns as the on-screen table, in the same order.
3. When the report has more than 10,000 rows, nothing is downloaded; the user sees "We'll email you the file" and the file is emailed to them instead.

Use change id `req-inventory-csv-export` and capability `inventory-export`.

Nobody is available to answer questions in this run. Ask them anyway, then use your recommended answer to each and mark it unconfirmed.
