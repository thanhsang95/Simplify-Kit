---
name: pr
description: "SimplifyKit (sk): draft the pull request description for a change under sk/changes/ (open or already archived) — the AB# link, what the spec delta adds, modifies or removes, task progress, open questions, and how risky the merge is — as text to paste; it creates no PR and writes no file. Use when the user says \"sk pr\", \"write the PR description for us-12345-...\", or wants the PR body for a change SimplifyKit planned."
metadata:
  author: Simplify
  version: "0.1.0"
---

Write the body of the pull request that ships one change, from its artifacts, as response text. The person pastes it into Azure DevOps or GitHub.

**It creates nothing.** No PR, no comment, no file, no push. Creating a PR in Azure DevOps is a write, and Azure DevOps is read-only everywhere in this kit; a `pr.md` under `sk/changes/` would be one more committed copy of what the artifacts already say. If asked to open the PR too, give the body and say that is the person's step.

## Step 1 — Select the change

The id given in the request → the change discussed earlier in this conversation → otherwise list and ask. **Look under `sk/changes/archive/<id>/` too**, unlike every other command: the README tells people to archive before they push, so the usual moment for this command is right after `/sk:archive`. When the id exists in both places, the open one wins and you say the archived copy was ignored.

Announce `Using change: <id> (open | archived)`.

## Step 2 — Read the change from disk

Read, fresh: `proposal.md`, `specs/**/spec.md`, `design.md` if present, `tasks.md`. Nothing else is a source. The PR body states only what these files say — never a test result, a reviewer, a screenshot or a number they do not contain.

When the Bash tool is available, also read `git diff --stat <base>...HEAD` (base: the repository's default branch) so the body can say which code paths the change touched. Without it, leave that line out; never guess file names.

## Step 3 — Write the body

Use exactly these sections, in this order. Leave a section out when it has nothing to say, never fill it with "N/A".

```markdown
## Summary

AB#<id> — <work item title>          ← "Request: <short title>" for a req- change; no AB# line

<Two or three sentences: what changes for a user or a caller, from proposal.md's Summary.
For a Bug: what was wrong (the Symptom line) and what it does now.>

## Spec changes

**<capability>**
- Added: <requirement name> (<n> scenarios)
- Modified: <requirement name> — <what changed, one line>
- Removed: <requirement name> — <the one-line reason from the delta>

## Contracts

<Each interface under design.md → ## Contracts, signature as written. Drop when design was skipped.>

## Tasks

<done>/<total> done. <Each unticked task, verbatim.>

## Open before merge

- Q<n> — <question> (in <scenario>)    ← each [[OPEN:Q<n>]] still in the delta; /sk:archive refuses while one stands
- <each unconfirmed entry under ## Assumptions, and each Gap>

## Evidence

<To fill in by the author: how the scenarios were checked.>

## Merge danger

<One-way or two-way door, and the blast radius — see below.>
```

- **Spec changes** come from the delta, archived or not: the delta still holds the requirement names and the scenarios. A `Modified` line says what changed, so a reviewer looks at that line of `sk/specs/` and not at the whole requirement — `MODIFIED` restates the requirement in full, and a reviewer reading the delta cannot tell the changed scenario from the copied ones
- **Evidence** is the person's to write. List each scenario name as a line to tick, and add what this conversation actually showed — a `/sk:verify` report, an `/sk:apply` close-out naming tests seen failing then passing. When none of that happened here, the list of scenarios is the whole section. A test that was written but not run is "written, not run", never "passes"
- **Merge danger.** Two-way door: the change only adds behaviour and can be reverted with the commit. One-way door: anything a revert does not undo — a `## Contracts` entry that changes a database schema, a public endpoint or an event other systems consume; a `Removed` requirement; data written in a new shape. The blast radius is who sees a mistake: name the actors and callers the scenarios mention, and, when `git diff --stat` was read, the areas it touched. Say which it is and why in two or three lines; never call a change safe because it is small
- **Open before merge** carries the blockers forward: an open-question marker in the delta means `/sk:archive` will refuse, and a change not yet archived (`open` in Step 1) means the `sk/specs/` diff is not in this PR yet — add "`/sk:archive <id>` not run: the living spec does not show this change yet" when that is the case

## Step 4 — Close out

Print the body in one fenced block so it copies cleanly, then one line naming anything that should be fixed before the PR is opened (open questions, unticked tasks, not archived). Nothing else.

## Guardrails

- Creates no PR and writes no file, on any platform, even when asked; Azure DevOps stays read-only
- Every line traces to `proposal.md`, the delta, `design.md`, `tasks.md`, or something this conversation actually showed. No invented test results, reviewers, links or numbers
- Reads archived changes too; never lists `archive/` as an open change when asked what is open
- Never claims "safe" or "low risk" without saying what makes it a two-way door
