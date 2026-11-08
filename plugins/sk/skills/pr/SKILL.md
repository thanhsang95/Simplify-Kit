---
name: pr
description: "SimplifyKit (sk): draft the pull request description for a change under sk/changes/ (open or already archived) — the AB# link, what the spec delta adds, modifies or removes, task progress, open questions, and how risky the merge is — as text to paste; it creates no PR and writes no file. Use when the user says \"sk pr\", \"write the PR description for us-12345-...\", or wants the PR body for a change SimplifyKit planned."
metadata:
  author: Simplify
  version: "0.2.0"
---

Write the body of the pull request that ships one change, from its artifacts, as response text. The person pastes it into Azure DevOps or GitHub.

**It creates nothing** — no PR, comment, file or push. Creating a PR is an Azure DevOps write, and a `pr.md` would be one more copy of the artifacts. If asked to open the PR, give the body and say that is the person's step.

## Step 1 — Select the change

The id in the request → the change discussed earlier → otherwise list and ask. **Look under `sk/changes/archive/<id>/` too** — people archive before pushing, so this usually runs right after `/sk:archive`. In both places → the open one wins; say so.

Announce `Using change: <id> (open | archived)`.

## Step 2 — Read the change from disk

Read fresh: `proposal.md`, `specs/**/spec.md`, `design.md` if present, `tasks.md` — the only sources. Never a test result, reviewer, screenshot or number they do not contain. With Bash, also `git diff --stat <default-branch>...HEAD` for the paths touched; without it, leave that out and never guess file names.

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

## Out of scope

- <each entry under proposal.md's ## Out of scope, with its source>

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

- **Spec changes** come from the delta. A `Modified` line says what changed — `MODIFIED` restates the whole requirement, so a reviewer cannot otherwise tell the changed scenario from the copied ones
- **Evidence** is the person's: each scenario as a line to tick, plus only what this conversation showed (a `/sk:verify` report, tests seen failing then passing). Written but not run is "written, not run", never "passes"
- **Merge danger.** Two-way door: only adds behaviour, reverted with the commit. One-way: what a revert does not undo — a schema, public endpoint or consumed event in `## Contracts`, a `Removed` requirement, data in a new shape. Blast radius: the actors and callers the scenarios name, and the areas `git diff --stat` touched. Two or three lines with the reason; never "safe" because it is small
- **Open before merge**: open-question markers (`/sk:archive` will refuse), and for an open change "`/sk:archive <id>` not run: the living spec does not show this change yet"

## Step 4 — Close out

Print the body in one fenced block so it copies cleanly, then one line naming anything that should be fixed before the PR is opened (open questions, unticked tasks, not archived). Nothing else.

## Guardrails

- Creates no PR and writes no file, on any platform, even when asked; Azure DevOps stays read-only
- Every line traces to `proposal.md`, the delta, `design.md`, `tasks.md`, or something this conversation actually showed. No invented test results, reviewers, links or numbers
- Reads archived changes too; never lists `archive/` as an open change when asked what is open
- Never claims "safe" or "low risk" without saying what makes it a two-way door
