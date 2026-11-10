---
name: pr
description: "SimplifyKit (sk): draft the pull request description for a change under sk/changes/ (open or already archived) — for a draft PR that carries only the spec (spec review), or for the PR with the code (code review): the AB# link, what the spec delta adds, modifies or removes, task progress, open questions, and how risky the merge is — as text to paste; it creates no PR and writes no file. Use when the user says \"sk pr\", \"write the PR description for us-12345-...\", or wants the PR body for a change SimplifyKit planned."
metadata:
  author: Simplify
  version: "0.4.0"
---

Write the body of the pull request that ships one change, from its artifacts, as response text. The person pastes it into Azure DevOps or GitHub.

**It creates nothing** — no PR, comment, file or push. Creating a PR is an Azure DevOps write, and a `pr.md` would be one more copy of the artifacts. If asked to open the PR, give the body and say that is the person's step.

## Step 1 — Select the change

The id in the request → the change discussed earlier → otherwise list and ask. **Look under `sk/changes/archive/<id>/` too** — people archive before pushing, so this usually runs right after `/sk:archive`. In both places → the open one wins; say so.

Announce `Using change: <id> (open | archived)`.

## Step 2 — Pick the mode

- `--spec` or `--code` in the request wins
- Archived → **code review**
- With Bash: `git diff --name-only <default-branch>...HEAD` touches only `sk/` **and** no task in `tasks.md` is ticked (or there is no `tasks.md`) → **spec review**; otherwise code review
- Without Bash: no task ticked, or no `tasks.md` → spec review; otherwise code review. Unticked boxes do not prove no code exists — say the diff was not read

Announce `Mode: spec review | code review` and how to switch (`/sk:pr <id> --code` or `--spec`).

## Step 3 — Read the change from disk

Read fresh: `proposal.md`, `specs/**/spec.md`, `design.md` if present, `tasks.md` if present — the only sources. Never a test result, reviewer, screenshot or number they do not contain. With Bash, also `git diff --stat <default-branch>...HEAD` for the paths touched; without it, leave that out and never guess file names.

For the risk, also read `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` → `## Risk` (the one definition of door, blast radius and level), `sensitive:` in `sk/config.yaml`, and `proposal.md` → `## Risk (preliminary)`.

## Step 4 — Write the body

Use exactly the sections of the mode, in this order. Leave a section out when it has nothing to say, never fill it with "N/A".

### Spec review — a draft PR before the code

Reviewers read the spec while changing it is still cheap.

```markdown
## Summary

AB#<id> — <work item title>          ← "Request: <short title>" for a req- change; no AB# line

<Two or three sentences from proposal.md's Summary.>

## Review now

- <path of each delta file>, <path of design.md, if present>
- <what to decide: whether the criteria were read right, and each question below>

Not for this round: tasks.md and code.

## Spec changes

<As in code review below.>

## Contracts

<As in code review below; drop when design was skipped.>

## Gaps & assumptions

- <each Gap, each unconfirmed entry under ## Assumptions, each Q<n> under ## Open questions — what a reviewer can answer>

## Risk (preliminary)

<Level, door and sensitive areas copied from proposal.md, marked: estimate before any code exists.
proposal.md has no such section → say so, and rate it by conventions.md → ## Risk from the artifacts, marked: rated now, from the spec only.>
```

No **Tasks**, **Evidence**, **Open before merge** or **Merge danger** in this mode: there is no code to judge them by.

### Code review — the PR with the code

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

<Low | Medium | High: the door, the blast radius, any sensitive area touched — see below.>

Suggested tag: risk:<low | medium | high>
```

- **Spec changes** (both modes) come from the delta. A `Modified` line says what changed — `MODIFIED` restates the whole requirement, so a reviewer cannot otherwise tell the changed scenario from the copied ones
- **Evidence** is the person's: each scenario as a line to tick, plus only what this conversation showed (a `/sk:verify` report, tests seen failing then passing). Written but not run is "written, not run", never "passes". When this conversation showed a `/sk:verify` report, say to paste it as its own PR comment rather than into the description; otherwise say nothing about one. (Why, not for the body: an Azure DevOps description is short, and the latest report in a comment is the one that counts.)
- **Merge danger**: the level from `conventions.md` → `## Risk`, then two or three lines with the facts behind it — which door and why, the blast radius, each `sensitive:` glob the touched paths match. Without the diff, match the globs against the paths the artifacts name and say the diff was not read. Name a path only when it matches a glob; none listed → say so in a few words
  - **Compared with `## Risk (preliminary)`**: higher now → open the section with `Risk went up from <X> to <Y> because <what the code or artifacts show>`. Lower → if the preliminary level is `confirmed`, keep it and say what would let a person lower it; if `unconfirmed`, rate from the artifacts and name both levels. No such section → skip the comparison
  - **Suggested tag** last: the level as `risk:low`, `risk:medium` or `risk:high`, for the author to set on the PR. A suggestion; never set it yourself
- **Open before merge**: open-question markers (`/sk:archive` will refuse), and for an open change "`/sk:archive <id>` not run: the living spec does not show this change yet"

## Step 5 — Close out

Print the body in one fenced block so it copies cleanly, then one line naming anything that should be fixed before the PR is opened (open questions, unticked tasks, not archived) — in spec review, only what blocks reviewing the spec. Then one line on when the description is written: **spec review** → "Use this for the draft PR. At Publish, run `/sk:pr <id>` again and replace the description whole; between those two, updates go in comments." **Code review** → nothing more. Nothing else.

## Guardrails

- Creates no PR and writes no file, on any platform, even when asked; Azure DevOps stays read-only
- Every line traces to `proposal.md`, the delta, `design.md`, `tasks.md`, or something this conversation actually showed. No invented test results, reviewers, links or numbers
- Reads archived changes too; never lists `archive/` as an open change when asked what is open
- Never claims "safe" or "low risk" without saying what makes it a two-way door; when unsure, rates higher (`conventions.md` → `## Risk`). Never rates below a `confirmed` preliminary level on its own
