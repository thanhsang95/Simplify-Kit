---
# Same canary as propose-from-work-item/graders/no-write-outside-sk.md and
# apply-implements-tasks/graders/writes-code-outside-sk.md: a tool_used
# grader counts calls that MATCH, so a pattern broken in the direction of
# matching nothing would pass here silently no matter what the run did.
# apply-implements-tasks proves the pattern can match at all; this one and
# no-write-outside-sk.md assert it matches zero calls. Keep all three
# byte-identical.
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"(?![^"]*[\\/]sk[\\/])[^"]*"'
min: 0
max: 0
---
