---
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

/sk:ff us-12345-field-selector

There is no network access here, so read the work item from the offline copy at
./work-item-12345.json instead of fetching it or calling `az`. The capability is
`field-selector`.
