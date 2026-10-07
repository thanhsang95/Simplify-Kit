---
name: init
description: "SimplifyKit (sk): set up the sk/ spec workspace in this repository, or bring a workspace made by an older version up to date. Use when the user says \"sk init\", \"set up SimplifyKit\", \"initialize sk\", asks to start using SimplifyKit here, or asks to update or migrate an existing sk/ workspace. Creates sk/config.yaml, sk/specs/ and sk/changes/, appends a short pointer to the repo's CLAUDE.md, and gitignores sk/changes/archive/. Run this once per repository, before /sk:propose."
metadata:
  author: Simplify
  version: "0.3.0"
---

Set up the `sk/` workspace for SimplifyKit in the current repository.

SimplifyKit targets **Claude Code only**. Never create, read, or modify configuration for any other coding agent — no `AGENTS.md`, no `.opencode/`, no Codex prompts, no Cursor rules. If the repository has them, leave them exactly as they are and do not mention them as something to update.

## Step 1 — Never overwrite; migrate instead

If `sk/` already exists, this is not a fresh setup: skip Steps 2–7 and go to **Migrating an existing workspace** at the end. Do not rewrite `config.yaml`, do not "repair" anything beyond the list there, do not merge. Initialising twice is how a project silently loses its context file.

## Step 2 — Learn the repository

Read enough to fill `context` with facts, not placeholders. Look for:

- Build and test entry points — solution/project files, `package.json` scripts, `Makefile`
- Language and framework versions actually pinned in the repo
- Existing documentation under `docs/`, `README.md`, `.claude/rules/`, `.claude/CLAUDE.md`

**Reference existing documentation instead of copying it.** If the repo already has `docs/code-standards.md`, `context` should say to read it — not restate it. Copied text goes stale; a pointer does not.

**Do not point `context` at `CLAUDE.md` or `.claude/CLAUDE.md` itself, and do not enumerate the individual files under `.claude/rules/`.** Claude Code loads the repo's `CLAUDE.md` into every session automatically, so citing it in `context` is a no-op, not a pointer to something otherwise missed. If it indexes rule files by path, trust that index to route reading — repeating its contents in `context` just duplicates routing logic that already lives there.

## Step 3 — Read the Azure DevOps defaults

`/sk:propose` needs an org URL. Get it from the machine's existing configuration:

```bash
az devops configure --list
```

Take `organization` and `project` verbatim. **Store the full org URL** in `ado.orgUrl` — for example `https://contoso.visualstudio.com/`. Never store a short org name and never rebuild a URL from a template: legacy `*.visualstudio.com` organisations are still in use and `https://dev.azure.com/<name>` points somewhere else for them.

If the command fails, returns no defaults, or the Bash tool is not available in this session, leave `ado.orgUrl` and `ado.project` empty with a comment telling the user to fill them in, and say so in your report. Do not guess, do not derive them from the git remote, and do not let a missing org URL stop the rest of the setup.

## Step 4 — Write the workspace

Create, using `${CLAUDE_PLUGIN_ROOT}/templates/config.yaml` as the structure:

```
sk/config.yaml
sk/specs/.gitkeep
sk/changes/.gitkeep
```

`sk/specs/` is empty at this point by design. It fills up when `/sk:archive` merges a change's spec delta into it. `sk/changes/archive/` is not created here: `/sk:archive` creates it on first use, and it is not committed (next step).

`sk/context.md` (glossary) and `sk/adr/` (decision records) are not created here either. `/sk:archive` writes them the first time there is something to record.

## Step 4b — Keep archived changes out of git

Append `sk/changes/archive/` to the repository's `.gitignore`, under a one-line comment saying why: finished changes are recorded by the merged spec, `sk/adr/` and `sk/context.md`, so the archived copies would only be noise. Create `.gitignore` if there is none. **Append only** — never reorder or rewrite existing lines, and do nothing if the entry is already there.

Open changes under `sk/changes/<id>/` stay committed: they are what a teammate reviews and what `/sk:propose` and `/sk:archive` read to see other people's unarchived work. Ignore `sk/changes/` as a whole and both stop working across machines.

## Step 5 — Point CLAUDE.md at it

Find the repository's Claude Code instructions in this order and use the **first** that exists:

1. `./CLAUDE.md`
2. `./.claude/CLAUDE.md`

**Append** a short section to it. Never overwrite, never reflow the existing content, never reorder it. If neither file exists, create `./CLAUDE.md` containing only the new section.

The appended section should say what `sk/` is, list the commands (`/sk:propose`, `/sk:continue`, `/sk:apply`, `/sk:verify`, `/sk:archive`), and state when to use them — a handful of lines, not a manual. The details live in this plugin, not in the host repo.

## Step 6 — Report a planning-system conflict, do not resolve it

Check `.claude/rules/` for rules that already mandate a planning workflow — for example a rule that requires delegating to a `planner` agent and writing plans into a different directory.

If you find one, **report it**: name the file, quote the line, and tell the user that until a person adds an exception to that rule for work that goes through `/sk:propose`, that rule still wins and `/sk:apply` will be competing with it.

Do not edit `.claude/rules/`. Do not add a new rule file to out-vote the existing one — precedence between two rule files in the same directory is undefined, so a second file adds a second voice rather than an answer. This is a repository configuration change and it belongs to whoever owns the repository.

## Step 7 — Close out

Report the files created, that `sk/changes/archive/` was added to `.gitignore`, the `ado.orgUrl` recorded (or that it is blank and why), which CLAUDE.md was appended to, and any planning-system conflict found. Then tell the user the next step is `/sk:propose AB#<id>` — or `/sk:propose <request>` for work that has no work item.

## Migrating an existing workspace

A workspace made by SimplifyKit 0.1.x differs from a current one, and nothing in `sk/` records which version made it. So this detects by **what is actually there**, never by a version number, which makes every item safe to find again on a second run. Start read-only: report what exists (`config.yaml`, how many capabilities under `sk/specs/`, how many open changes and archived changes) and check the six items below.

**Never touch** `sk/config.yaml`, `sk/specs/`, any spec delta, a `tasks.md`, or the existing text of any artifact. Every edit below is an append.

| # | Detect | Action |
|---|---|---|
| 1 | `.gitignore` has no `sk/changes/archive/` line | Append it, as a fresh setup does (Step 4b) |
| 2 | An open change (under `sk/changes/`, not `archive/`) has `tasks.md` but neither `design.md` nor a `## Design` section in `proposal.md` | Append to its `proposal.md` a `## Design` section reading `Skipped — planned before /sk:continue existed.` Without it `/sk:continue` counts design as not done and writes a `design.md` for a change that was already planned and may already be built |
| 3 | An open change has no spec delta and its `proposal.md` has no `**AC source:**` line | Add `**AC source:** none yet` under the `**Type / State:**` line. The old `/sk:propose` only stopped there when acceptance criteria were missing. A change that already has a delta is left alone: `/sk:continue` reads that line only to write the delta |
| 4 | `git ls-files sk/changes/archive` lists files | **Report only.** Print `git rm -r --cached sk/changes/archive` and warn that teammates who pull it lose those folders from their working copies (history keeps them). Never run it: it changes other people's checkouts, so it is the team's call |
| 5 | There are archived changes under `sk/changes/archive/`, and there is no `sk/context.md` or an archived change with a `design.md` has no ADR carrying its id | **Report only.** Say how many archived changes there are and to run `/sk:archive backfill` **once** — it drafts one deduplicated glossary and an ADR for each change that qualifies, and asks a single time — **before** item 4, because after that only the local copy holds the rationale. Never list them for the person to run one by one |
| 6 | The `CLAUDE.md` section that a fresh `init` appends does not mention `/sk:continue` | Offer to append one line to the end of that file saying `/sk:continue <change-id>` writes the next planning artifact after `/sk:propose`. Never edit the existing section |

If none of the six applies, say the workspace is up to date and stop.

**With a person present:** show every item found, with the exact text it would add and to which file, in **one round**, and ask them to confirm the lot or drop some. Items 4 and 5 are informational and are shown regardless. Write nothing before the answer.

**When nobody can answer** — the request says so — apply items 1–3, which only append and need no judgement, and skip 4–6, printing them instead. Report exactly what was applied.

Close out by listing what was applied, what was skipped and why, and the commands left for a person to run.

## Guardrails

- Never overwrite an existing `sk/`; on one, migrate by appending only, and never touch `config.yaml`
- Detect what needs migrating from what is on disk, not from a version number
- Never run `git rm --cached` on the archive — print it
- Never touch configuration belonging to another coding agent
- Never edit `.claude/rules/`
- Append to CLAUDE.md and `.gitignore`, never overwrite
- Ignore `sk/changes/archive/` only — never `sk/changes/` as a whole
- Fill `context` from what you actually read; an unedited placeholder is worse than an empty field
- Store the full ADO org URL, never a reconstructed one
