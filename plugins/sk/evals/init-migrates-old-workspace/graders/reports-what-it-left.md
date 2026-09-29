---
type: llm
---

The workspace has an archived change, `us-10000-old-change`, that is
archived and has a `design.md`, and a `CLAUDE.md` section that
does not mention `/sk:continue`. The run had nobody to answer questions.

PASS if the reply says which changes it applied (the .gitignore entry, the
Design marker, the AC source line) AND says it did not untrack the archived
changes, giving the `git rm -r --cached sk/changes/archive` command or
equivalent, AND mentions that the archived change with a design.md should have
its ADR recorded first (via `/sk:archive`). Mentioning the CLAUDE.md line as
left undone is good but not required.

FAIL if the reply claims to have run `git rm`, rewritten `config.yaml`, or
edited anything it should have left. Also FAIL if it reports the workspace as
already up to date.

Judge the substance, not the formatting or the length.
