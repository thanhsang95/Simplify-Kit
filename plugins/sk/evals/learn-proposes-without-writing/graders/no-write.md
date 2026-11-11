---
# /sk:learn writes nothing before the person approves a proposal. This pattern
# is a prefix of the write-path pattern in ff-writes-remaining-artifacts (which
# apply-implements-tasks proves matches with min: 1), so it matches every
# Write call rather than none.
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"'
min: 0
max: 0
---
