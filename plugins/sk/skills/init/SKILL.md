---
name: init
description: "SimplifyKit (sk): set up the sk/ spec workspace in this repository, or bring a workspace made by an older version up to date. Use when the user says \"sk init\", \"set up SimplifyKit\", \"initialize sk\", asks to start using SimplifyKit here, or asks to update or migrate an existing sk/ workspace. Creates sk/config.yaml, sk/specs/ and sk/changes/, appends a short pointer to the repo's CLAUDE.md, and gitignores sk/changes/archive/. Run this once per repository, before /sk:propose."
metadata:
  author: Simplify
  version: "0.9.0"
---

Set up the `sk/` workspace in the current repository.

**Claude Code only.** Never create, read or modify another coding agent's configuration (`AGENTS.md`, `.opencode/`, Codex prompts, Cursor rules), and do not suggest updating it.

## Step 1 — Never overwrite

`sk/` already exists → skip to **Migrating an existing workspace**. Never rewrite `config.yaml` or merge — initialising twice is how a project loses its context file.

## Step 2 — Learn the repository

Fill `context` with facts, not placeholders: build and test entry points, pinned language and framework versions, existing docs. **Point to documentation instead of copying it** (copies go stale). Never point at `CLAUDE.md` (already loaded every session) or list the files under `.claude/rules/`.

## Step 3 — Azure DevOps defaults

From `az devops configure --list`, take `organization` and `project` verbatim. **Store the full org URL** in `ado.orgUrl` (e.g. `https://contoso.visualstudio.com/`) — never a short name or a rebuilt `dev.azure.com` URL, which points elsewhere for legacy orgs. If it fails or Bash is unavailable, leave both empty with a comment to fill them in, say so, and carry on; never guess from the git remote.

## Step 4 — Write the workspace

From `${CLAUDE_PLUGIN_ROOT}/templates/config.yaml`, create `sk/config.yaml`, `sk/specs/.gitkeep`, `sk/changes/.gitkeep`. `/sk:archive` creates `sk/changes/archive/`, `sk/context.md` and `sk/adr/` when needed.

## Step 4b — Ignore archived changes

Append `sk/changes/archive/` to `.gitignore` (create it if missing) with a one-line comment: finished changes live on in the merged spec, `sk/adr/` and `sk/context.md`. **Append only**; skip if present. Never ignore `sk/changes/` as a whole — open changes are reviewed by teammates and read by `/sk:propose` and `/sk:archive`.

## Step 4c — Offer the pre-push check

Nothing in a skill runs on `git push`, so a finished but unarchived change can reach the remote unnoticed. A `pre-push` hook stops a push holding a change with every task ticked still under `sk/changes/<id>/`, or an `[[OPEN:Q<n>]]` marker in `sk/specs/`; `--no-verify` bypasses it.

Offer it only with Bash **and** a person to answer — it writes inside `.git/` and changes every later push, so never unattended (say in Step 7 that re-running `/sk:init` with a person sets it up). Show the two files, ask once. On yes:

1. Copy `${CLAUDE_PLUGIN_ROOT}/templates/git-hooks/pre-push` to `sk/hooks/pre-push` (committed, shared by the team). Never overwrite an existing one
2. The shim goes to `pre-push` in the directory `git rev-parse --git-path hooks` prints. If `git config core.hooksPath` is set (a hook manager owns hooks) or the target exists, **write nothing there**: print `sh sk/hooks/pre-push "$@"` to add to their own hook, noting it needs the hook's stdin. Otherwise copy `${CLAUDE_PLUGIN_ROOT}/templates/git-hooks/pre-push-shim` there and `chmod +x` it

`.git/hooks` is not cloned, so each teammate runs `/sk:init` once (migration item 7).

## Step 5 — Point CLAUDE.md at it

**Append** a short section to the first of `./CLAUDE.md`, `./.claude/CLAUDE.md` that exists (else create `./CLAUDE.md`) — never rewrite existing content. A handful of lines: what `sk/` is and when to use `/sk:propose`, `/sk:continue`, `/sk:apply`, `/sk:verify`, `/sk:archive`, `/sk:pr`, `/sk:questions`.

## Step 6 — Report a planning-system conflict

A rule in `.claude/rules/` that already mandates a planning workflow (e.g. a `planner` agent writing plans elsewhere) → **report it**: file, quoted line, and that it wins until a person adds an exception for `/sk:propose` work. Never edit `.claude/rules/` or add a rule file to out-vote it — precedence between rule files is undefined.

## Step 7 — Close out

Report files created, the `.gitignore` entry, the `ado.orgUrl` (or why it is blank), which CLAUDE.md was appended to, the pre-push outcome, and any conflict. Next step: `/sk:propose AB#<id>` or `/sk:propose <request>`.

End with one line: the optional `sk-status` plugin (`/plugin install sk-status@simplify`) shows each change's progress and next command; `sk` works the same without it. Never install it yourself.

## Migrating an existing workspace

Detect by **what is on disk**, never by a version number, so every item is safe to find twice. Start read-only: report what exists (`config.yaml`, capabilities, open and archived changes) and check the items below. **Never touch** `config.yaml`, `sk/specs/`, deltas, `tasks.md` or existing artifact text — every edit is an append.

| # | Detect | Action |
|---|---|---|
| 1 | `.gitignore` lacks `sk/changes/archive/` | Append it (Step 4b) |
| 2 | An open change has `tasks.md` but no `design.md` and no `## Design` in `proposal.md` | Append `## Design` reading `Skipped — planned before /sk:continue existed.` — else `/sk:continue` writes a design for a change already planned |
| 3 | An open change has no delta and no `**AC source:**` line | Add `**AC source:** none yet` under `**Type / State:**` |
| 4 | `git ls-files sk/changes/archive` lists files | **Report only**: print `git rm -r --cached sk/changes/archive` and warn teammates who pull it lose those folders locally. Never run it |
| 5 | Archived changes exist, and no `sk/context.md`, or one with a `design.md` has no ADR carrying its id | **Report only**: run `/sk:archive backfill` **once**, **before** item 4 — after it only the local copy holds the rationale |
| 6 | The appended `CLAUDE.md` section does not mention `/sk:continue` | Offer to append one line at the end saying `/sk:continue <change-id>` writes the next planning artifact |
| 7 | Bash is available, and `sk/hooks/pre-push` is missing, or the clone's `pre-push` hook does not mention it | Offer Step 4c — all of it, or only the shim. Without Bash, skip silently |

None applies → the workspace is up to date.

**With a person:** show every item with the exact text and file in **one round** (`${CLAUDE_PLUGIN_ROOT}/reference/asking-the-user.md`); items 4 and 5 are information, not questions. Write nothing before the answer. **When nobody can answer:** apply 1–3 and print 4–7.

Close out with what was applied, what was skipped and why, and commands left for a person.

## Guardrails

- Never overwrite `sk/`, `config.yaml`, `CLAUDE.md` or `.gitignore` — append only
- Never run `git rm --cached` on the archive; never ignore all of `sk/changes/`
- Pre-push only with a person's yes; never overwrite a hook or touch a hook manager's directory
- Never touch another agent's configuration or `.claude/rules/`
- Fill `context` from what you read; store the full org URL
