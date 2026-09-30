---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

Continue change us-12345-field-selector. There is no network access here, so read
the work item from the offline copy at ./work-item-12345.json instead of fetching
it or calling `az`.

The capability is `field-selector`.
