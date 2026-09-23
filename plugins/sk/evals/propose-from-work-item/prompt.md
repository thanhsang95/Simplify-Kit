---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

Plan work item AB#12345. There is no network access here, so use the offline copy
at ./work-item-12345.json instead of calling `az`.

Use change id `us-12345-field-selector` and capability `field-selector`.
