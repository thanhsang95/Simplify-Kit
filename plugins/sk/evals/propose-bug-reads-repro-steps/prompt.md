---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

Plan work item AB#21100. There is no network access here, so use the offline copy
at ./work-item-21100.json instead of calling `az`. Linked work items' offline
copies follow the same naming convention: ./work-item-<id>.json.

Use the slug `hide-expired` in the change id (choose its prefix the way the skill says) and capability `catalog-search`.

Nobody is available to answer questions in this run. Ask them anyway, then use your recommended answer to each and mark it unconfirmed.
