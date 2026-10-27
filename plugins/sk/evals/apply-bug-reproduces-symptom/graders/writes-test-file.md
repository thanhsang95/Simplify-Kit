---
# Same pattern as apply-implements-tasks/graders/writes-test-file.md: the
# regression test is written before the fix even though it cannot be run.
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"(?![^"]*[\/]sk[\/])[^"]*(?:[\/]tests?[\/]|\.(?:test|spec)\.)[^"]*"'
min: 1
---
