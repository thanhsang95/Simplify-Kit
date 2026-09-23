---
# file_exists only sees files CREATED during the run, so this asserts the copy
# landed in the archive. It cannot assert the original is gone: the run has no
# shell, so nothing can delete a directory. That half is checked by hand in the
# host repository — see the plan's verification section.
type: file_exists
path: sk/changes/archive/us-12345-field-selector/proposal.md
---
