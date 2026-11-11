---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite]
---

/sk:learn since 2026-10-10

There is no network access here, so read the offline copies under ./ado/ instead
of calling Azure DevOps: ./ado/pull-requests.json (the completed PRs in the
period), ./ado/pr-<id>-threads.json (each PR's threads and comments),
./ado/escaped-bugs.json (the query result for Bugs tagged `escaped`), and
./ado/work-item-<id>.json with ./ado/work-item-<id>-comments.json for each Bug.
