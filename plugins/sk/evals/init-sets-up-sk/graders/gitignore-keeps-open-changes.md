---
# Open changes must stay committed: they are what a teammate reviews, and what
# /sk:propose and /sk:archive read to see other people's unarchived work.
# Ignoring sk/changes/ as a whole would break both across machines. JS regex has
# no multiline by default, hence flags: m.
type: regex
pattern: '^\s*/?sk/changes/?\*{0,2}\s*$'
flags: m
match: not_contains
target:
  source: file
  path: .gitignore
---
