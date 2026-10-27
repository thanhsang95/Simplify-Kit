---
# Any Write whose path is not questions.md. Its counterpart questions-file-exists
# proves a Write to questions.md happens, so this pattern is not vacuous.
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"(?![^"]*questions\.md")[^"]*"'
min: 0
max: 0
---
