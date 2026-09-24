---
name: init
description: "SimplifyKit (sk): set up the sk/ spec workspace in this repository. Use when the user says \"sk init\", \"set up SimplifyKit\", \"initialize sk\", or asks to start using SimplifyKit here. Creates sk/config.yaml, sk/specs/ and sk/changes/, and appends a short pointer to the repo's CLAUDE.md. Run this once per repository, before /sk:propose."
metadata:
  author: Simplify
  version: "0.1.0"
---

Set up the `sk/` workspace for SimplifyKit in the current repository.

SimplifyKit targets **Claude Code only**. Never create, read, or modify configuration for any other coding agent — no `AGENTS.md`, no `.opencode/`, no Codex prompts, no Cursor rules. If the repository has them, leave them exactly as they are and do not mention them as something to update.

## Step 1 — Refuse to overwrite

If `sk/` already exists, stop. Report what is already there (`config.yaml`, how many capabilities under `sk/specs/`, how many changes under `sk/changes/`) and tell the user this repo is already initialised. Do not rewrite `config.yaml`, do not "repair" anything, do not merge. Initialising twice is how a project silently loses its context file.

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
sk/changes/archive/.gitkeep
```

`sk/specs/` is empty at this point by design. It fills up when `/sk:archive` merges a change's spec delta into it.

## Step 5 — Point CLAUDE.md at it

Find the repository's Claude Code instructions in this order and use the **first** that exists:

1. `./CLAUDE.md`
2. `./.claude/CLAUDE.md`

**Append** a short section to it. Never overwrite, never reflow the existing content, never reorder it. If neither file exists, create `./CLAUDE.md` containing only the new section.

The appended section should say what `sk/` is, list the four commands, and state when to use them — a handful of lines, not a manual. The details live in this plugin, not in the host repo.

## Step 6 — Report a planning-system conflict, do not resolve it

Check `.claude/rules/` for rules that already mandate a planning workflow — for example a rule that requires delegating to a `planner` agent and writing plans into a different directory.

If you find one, **report it**: name the file, quote the line, and tell the user that until a person adds an exception to that rule for work that starts from an Azure DevOps work item, that rule still wins and `/sk:apply` will be competing with it.

Do not edit `.claude/rules/`. Do not add a new rule file to out-vote the existing one — precedence between two rule files in the same directory is undefined, so a second file adds a second voice rather than an answer. This is a repository configuration change and it belongs to whoever owns the repository.

## Step 7 — Close out

Report the files created, the `ado.orgUrl` recorded (or that it is blank and why), which CLAUDE.md was appended to, and any planning-system conflict found. Then tell the user the next step is `/sk:propose AB#<id>`.

## Guardrails

- Never overwrite an existing `sk/`
- Never touch configuration belonging to another coding agent
- Never edit `.claude/rules/`
- Append to CLAUDE.md, never overwrite
- Fill `context` from what you actually read; an unedited placeholder is worse than an empty field
- Store the full ADO org URL, never a reconstructed one
