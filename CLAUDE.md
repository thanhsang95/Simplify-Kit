# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

SimplifyKit (`sk`) is a **Claude Code plugin**, markdown-only — no runtime, no build, no deploy. It packages five skills (`/sk:init`, `/sk:propose`, `/sk:continue`, `/sk:apply`, `/sk:archive`) that turn an Azure DevOps work item into spec artifacts (`sk/specs/`, `sk/changes/`) in a *consuming* repository, then implement and merge them. This repo's own content is the plugin's skills, templates, reference docs, and eval suite — there is no application code here to run.

Read `README.md` for the full user-facing workflow and `CONTRIBUTING.md` for maintainer structure before making non-trivial changes.

## Structure

```
.claude-plugin/marketplace.json      marketplace "simplify"
plugins/sk/
  .claude-plugin/plugin.json         manifest: name, version, description
  skills/{init,propose,continue,apply,archive}/SKILL.md
  templates/                         file skeletons skills copy into the consuming repo
  reference/                         conventions.md, azure-devops.md, playbook-mapping.md — read by skills at runtime
  evals/                             claude plugin eval suite (17 cases)
```

Skills reference `reference/` and `templates/` via `${CLAUDE_PLUGIN_ROOT}/...`. **Never use relative paths there** — a real run showed the model resolving `reference/conventions.md` as `skills/propose/reference/conventions.md` and silently reading nothing, while the output still looked plausible.

## The core invariant: `MODIFIED` restates the full requirement

`/sk:archive` treats `## MODIFIED Requirements` as a full block replacement, not a patch: it replaces the matching requirement in `sk/specs/<capability>/spec.md` with exactly what the delta holds. A delta that omits an untouched scenario deletes that scenario from the living spec — silently, because the requirement name still matches and nothing reports a conflict.

This rule is encoded in **three places that must stay in sync**:
- `plugins/sk/reference/conventions.md` (`### MODIFIED restates the entire requirement`)
- `plugins/sk/templates/spec-delta.md` (the `MODIFIED` example)
- `plugins/sk/skills/archive/SKILL.md` (the validation check)

Editing one without checking the other two is the easiest way to break this repo silently — there is no test that catches drift between them except the scenario-count check `archive` itself runs at merge time (fewer scenarios after merge than before → stop and ask). Treat that check as a safety net, not the guarantee; restating in full is the actual guarantee.

## Working on skills

- Each `SKILL.md` frontmatter `name` must match its directory name — that's what produces `/sk:<name>`.
- `description` must start with `"SimplifyKit (sk):"` and state when to use it — this is what lets Claude Code pick the skill over other installed skills without the user typing its name.
- Keep `SKILL.md` short; push detail into `reference/`.
- If a rule exists because of a real observed failure, say so inline — an unexplained rule gets "simplified" away by someone later.
- Planning is split in two steps: `/sk:propose` writes `proposal.md` only; `/sk:continue` then writes one artifact per invocation (spec delta → design → tasks), deriving what is done from the files on disk — there is no status CLI. `/sk:continue` never starts a change and refuses a spec delta while `proposal.md` says `**AC source:** none yet`
- The "Planning boundary" paragraph appears in both `propose` and `continue`. Its wording was measured against real violations (see `CHANGELOG.md`), so change both together and re-run `propose-does-not-auto-apply`
- `/sk:propose` only accepts `AB#<id>` or a work item URL — never a bare integer, since bare numbers already mean PR id in this repo's own conventions.
- `/sk:archive` is the only skill with a destructive operation (directory move, full-block requirement replacement); it validates everything before writing anything (see `plugins/sk/skills/archive/SKILL.md`).

## Verifying a change (cheap → expensive)

1. **Always cheap:**
   ```bash
   claude plugin validate    # run from plugins/sk
   ```
   Also spot-check the two manifests parse as JSON (`.claude-plugin/marketplace.json`, `plugins/sk/.claude-plugin/plugin.json`) and that every `SKILL.md` frontmatter `name` matches its directory.

2. **A change you made in this repo will not show up for an already-installed plugin.** The installed copy is a version-locked cache at `~/.claude/plugins/cache/simplify/sk/<version>/`. To actually exercise a change: bump `version` in `plugins/sk/.claude-plugin/plugin.json`, `claude plugin update sk@simplify`, then test in a **new** Claude Code session.

3. **Eval suite** (`plugins/sk/evals/`, 17 cases, costs real money — do not run without the user's go-ahead and an explicit `--max-cost-usd`):
   ```bash
   cd plugins/sk
   # Windows only — WSL's bash on default PATH breaks every scaffolded case
   # with "scaffold failed (exit 1)"; this looks like a regression but isn't:
   $env:PATH = "C:\Program Files\Git\bin;" + $env:PATH

   # cheap iteration on one case:
   claude plugin eval . --case <case-name> --runs 1 --ablation none \
     --allow-tools Write Edit --scaffold --keep-temp --max-cost-usd 2

   # full gated run (three commands, different thresholds — see plugins/sk/evals/README.md):
   claude plugin eval . --tag wi   --threshold 0.95 --allow-tools Write Edit --scaffold --no-publish
   claude plugin eval . --tag init --threshold 0.85 --allow-tools Write Edit --scaffold --no-publish
   claude plugin eval . --tag core --threshold 0.8  --allow-tools Write Edit --scaffold --no-publish
   ```
   Gating is by `--tag`, not `--case` (`--case` is singular). See `plugins/sk/evals/README.md` for the tag→case table and eval-writing gotchas (JS regex has no multiline by default; `tool_used` with `min:0,max:0` passes silently if `input_match` is broken; `file_exists` only sees files created *during* the run).

4. **Never covered by eval, verify by hand only:** the `az` CLI path (eval runs have no Bash grant on Windows), and any delete/move (so `/sk:archive`'s directory move and the "old copy is gone" behavior needs manual pilot verification in a real consuming repo).

## Hard constraints specific to this repo

- **Claude Code only.** Never create or touch `AGENTS.md`, `.opencode/`, Codex prompts, Cursor rules, or any other coding agent's config — in this repo or in a repo `/sk:init` runs against. This is a settled decision, not a gap to fill.
- **Azure DevOps access is read-only, everywhere in this kit.** No comments, no Task creation, no state changes. Never add code paths that write to ADO.
- Work item text arrives as HTML — always strip tags and decode entities before it reaches a spec (see `plugins/sk/reference/azure-devops.md`).
- `plugins/sk/evals/**/fixture.sh` fixtures embed real work-item HTML *shape* with names/orgs/ids replaced by invented ones. Before touching or adding a fixture, check the pre-push checklist in `CHANGELOG.md` and re-sanitize — fixtures ship inside the plugin, so every `/plugin install` copies them to another machine.
- Do not add a CLI, auto-apply chaining from `/sk:propose`, or a freeform (non-work-item) entry point without the user explicitly asking — these are documented as out-of-scope decisions in `docs/PLAN.md`, not omissions.
