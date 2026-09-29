---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

Continue change us-31200-csv-export. There is no network access here, so read
the work item from the offline copy at ./work-item-31200.json instead of fetching
it or calling `az`.

The capability is `csv-export`.
