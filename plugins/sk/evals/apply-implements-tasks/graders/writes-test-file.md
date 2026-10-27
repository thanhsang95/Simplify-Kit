---
# /sk:apply writes each scenario's test before its code (reference/tdd.md).
# The run has no shell, so the test cannot be run — but it can still be
# written, and this checks it was: a Write outside sk/ to a path that looks
# like a test (a tests/ or test/ directory, or a .test. / .spec. file).
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"(?![^"]*[\\/]sk[\\/])[^"]*(?:[\\/]tests?[\\/]|\.(?:test|spec)\.)[^"]*"'
min: 1
---
