---
name: learn
description: "SimplifyKit (sk): turn a month of review data from Azure DevOps — completed PRs, their last /sk:verify report and its Disposition column, thread statuses, Bugs tagged escaped — into proposed fixes at the source (lint config, the code standards file, rules in sk/config.yaml, kit prompts) and draft eval cases for escapes /sk:verify missed. Only when the user explicitly runs /sk:learn, typically in a monthly review meeting. Reads only; writes a file only after a person approves that proposal."
disable-model-invocation: true
metadata:
  author: Simplify
  version: "0.1.0"
---

Read what review found over a period, count it, and propose changes that stop the same findings from coming back — at the cheapest layer that can catch them. Only a person typing `/sk:learn` starts it (`disable-model-invocation`): it reads a month of Azure DevOps data, which nobody should get as a side effect of another request.

**Reads only, then asks.** It writes nothing to Azure DevOps, ever, and nothing in the repository until a person approves that one proposal. It keeps no review log: the data stays on Azure DevOps, and a copy in the repo would drift from it.

## Step 1 — Scope

`sk/` must exist; if not, point at `/sk:init` and stop. Read `sk/config.yaml`: `ado` (org and project), the code standards file `context` points at, and `rules`.

The period is the last 30 days unless the request gives another (`since 2026-10-01`, `last 60 days`). Announce `Period: <from> — <to>`.

**Offline:** when the request names local JSON files (PRs, threads, work items), read those instead and fetch nothing.

## Step 2 — Read

Follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` — `## Get the org and a token`, `## Pull requests (read-only)` and `## Work item queries (read-only)`. REST with a token, never `az boards` / `az devops invoke` (they corrupt non-ASCII on this org); never print the token. Only GET requests, and the WIQL POST that only reads.

1. **Completed PRs** in the period
2. **Each PR's threads.** The last comment that starts `## Verification report` is that PR's report (format: `${CLAUDE_PLUGIN_ROOT}/skills/verify/SKILL.md`, its *Report* step). Take its `Round:` line, every `V<n>` with its severity and text — `### Code health` and `### Still open from round <n-1>` included — and its Disposition table: `fixed`, `wrong`, `intended`, `wontfix`, or blank. A PR with no report counts as *no report*, never as clean
3. **Thread statuses** (`active`, `fixed`, `wontFix`, `closed`, `byDesign`, `pending`) — a cross-check only. **Dispositions come from the Disposition column**: `closed` is a generic close, so it never counts as `wrong`, and a blank disposition stays blank
4. **Bugs tagged `escaped`** changed in the period, with their comments and links. The layer that missed it is the `Should have been caught by:` line in a comment or the linked fix's `proposal.md` (`## Escape`); none → `not recorded`

A failed request → report the real error and stop. **Never invent a PR, finding or count.**

## Step 3 — Count

Print one compact summary:

- PRs read; PRs with a report
- **Rounds until clean**: the `Round:` of each PR's last report. A last report that still lists a CRITICAL was not clean — count it apart
- **Findings by disposition**: `fixed` / `wrong` / `intended` / `wontfix` / blank
- **Recurring kinds**: group findings by the kind of problem (as `verify` matches them — file area, requirement, kind; not wording). List each kind seen **3 or more times**, with its `V<n>` and PR ids
- **Escapes by layer missed**: `spec` / `design` / `standards` / `lint` / `test` / `verify` / `human review` / `not recorded`, with Bug ids

Only numbers the data shows, each traceable to PR or Bug ids. **Fewer than 20 findings in total → say the sample is too small for reliable conclusions**, and mark every proposal as tentative.

## Step 4 — Propose fixes at the source

One proposal per recurring kind and per layer with escapes, numbered `L1`, `L2`, … Put each at the **first** layer in this order that can catch it — earlier layers run on every build and do not depend on a model reading a prompt:

1. **Lint / analyzer config** (`.editorconfig`, ESLint, Roslyn analyzers, …)
2. **The code standards file** `context` points at
3. **`rules` in `sk/config.yaml`**
4. **A kit prompt** — text only, for the SimplifyKit maintainers: the kit is not in this repository

Each is a unified diff against the file as it is on disk now (read it first; a missing file → say so, and the diff creates it), with the findings or Bugs behind it.

**Also propose deleting or narrowing a rule** whose findings are mostly `wrong` (3 or more): a rule that keeps producing wrong findings teaches people to skip the report.

## Step 5 — Draft eval cases for `verify` escapes

For each escape whose layer is `verify`, draft a case as **text in the reply only**: `case.yaml`, `prompt.md`, a minimal `fixture.sh` that reproduces the shape of the code that slipped through, and one grader asking one question. Evals live in the SimplifyKit plugin repo, not here — never write them.

Fixtures ship to every machine that installs the plugin: **strip customer and partner names, EDI payloads, credentials, tokens, connection strings and real people's names**, replace them with invented ones, and say which kinds were replaced — without repeating the values.

## Step 6 — Ask, then write only what was approved

Show every proposal and draft first, then ask in **one round** to approve, edit or drop each `L<n>` (`${CLAUDE_PLUGIN_ROOT}/reference/asking-the-user.md`). Write only approved diffs, exactly as shown, only in this repository. Kit prompt changes and eval drafts are never written.

**When nobody can answer** — the request says so — write nothing and print everything. Silence is not approval to change the project's rules.

## Guardrails

- Azure DevOps is read-only: no comments, tags, state changes or thread updates, even if asked
- No file before approval; no review log or report file at all
- `closed` is not `wrong`; blank is not a disposition
- No number, finding or cause the data does not show
