---
# Canary for the planning-boundary graders in propose-from-work-item.
#
# Those graders assert this exact pattern matches ZERO calls. A tool_used
# grader counts calls that MATCH, so a pattern broken in the direction of
# matching nothing would pass there silently. Here the run is supposed to write
# code outside sk/, so min: 1 proves the pattern can match at all.
#
# Keep this input_match byte-identical to the one in
# propose-from-work-item/graders/no-write-outside-sk.md.
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"(?![^"]*[\\/]sk[\\/])[^"]*"'
min: 1
---
