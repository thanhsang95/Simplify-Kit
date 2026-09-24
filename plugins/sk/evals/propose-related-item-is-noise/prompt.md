---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

Plan work item AB#21000. There is no network access here, so use the offline copy
at ./work-item-21000.json instead of calling `az`. Linked work items' offline
copies follow the same naming convention: ./work-item-<id>.json.

Use change id `us-21000-expiry-filter` and capability `expiry-filter`.
