---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

Plan work item AB#20800. There is no network access here, so use the offline copy
at ./work-item-20800.json instead of calling `az`. If it links to another work
item, that item's offline copy follows the same naming convention:
./work-item-<id>.json.

Use change id `us-20800-bulk-export` and capability `bulk-export`.
