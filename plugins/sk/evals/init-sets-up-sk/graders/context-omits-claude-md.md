---
# .claude/CLAUDE.md is auto-loaded by Claude Code at the start of every
# session, so pointing `context` at it (or at the individual rule files it
# already indexes) is a redundant instruction, not a useful pointer. The
# fixture seeds a real .claude/CLAUDE.md and .claude/rules/ so this grader
# can catch init citing them anyway.
type: regex
pattern: '\.claude[/\\](CLAUDE\.md|rules)'
match: not_contains
target:
  source: file
  path: sk/config.yaml
---
