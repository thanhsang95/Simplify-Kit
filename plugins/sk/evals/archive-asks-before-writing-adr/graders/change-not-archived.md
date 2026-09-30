---
# file_exists only sees files created during the run, so this asserts no copy
# landed in the archive. The run has no shell, so it could not have removed the
# original either way.
type: file_exists
path: sk/changes/archive/**
exists: false
---
