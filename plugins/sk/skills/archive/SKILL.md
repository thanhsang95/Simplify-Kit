---
name: archive
description: "SimplifyKit (sk): close a finished change — merge its spec delta into the living spec under sk/specs/ and move the change into sk/changes/archive/. Use when the user says \"sk archive\", \"archive the change\", or a change's tasks are all complete and its requirements should become part of the project's specification."
metadata:
  author: Simplify
  version: "0.1.0"
---

Merge a finished change's spec delta into `sk/specs/`, then move the change into `sk/changes/archive/`.

This is the only SimplifyKit command that overwrites and moves things. So it runs in two phases: **validate everything first, write nothing until every check passes.** A merge that stops halfway leaves `sk/specs/` partly updated with the change still in place, and rerunning it merges the same requirements twice.

## Step 1 — Select the change

Same as `/sk:apply`: the id in the request → the one under discussion → the only open change → otherwise list and ask. Exclude `archive/` when listing. Announce `Archiving change: <id>`.

## Phase 1 — Validate. Write nothing.

Read `sk/changes/<id>/tasks.md`, every `sk/changes/<id>/specs/**/spec.md`, and the matching `sk/specs/<capability>/spec.md` for each capability the change touches. Then run **all** of the checks below across **all** capabilities before writing anything. Collect every problem and report them together — do not fix one, write, and discover the next.

### 1. Tasks are finished

Any `- [ ]` left in `tasks.md` → stop. Report which tasks are open and point at `/sk:apply`.

### 2. `ADDED` must not already exist

A requirement under `## ADDED Requirements` whose name already appears in `sk/specs/<capability>/spec.md` → **stop and ask**. Merging it produces two requirements with the same name and nothing to distinguish them. The user decides whether it should have been `MODIFIED`, or whether one of them needs renaming.

### 3. `MODIFIED` / `REMOVED` must have a target — and "missing" has two meanings

A requirement under `## MODIFIED Requirements` or `## REMOVED Requirements` that is not in `sk/specs/<capability>/spec.md`: **before concluding anything, search the other changes' deltas** — `sk/changes/*/specs/<capability>/spec.md`, excluding `archive/`.

- **Found in another change that has not been archived yet** → this is an ordering matter, not a mistake. That change introduced the requirement and this one builds on it; `/sk:propose` is *supposed* to read unarchived deltas. Stop with: *"`<requirement>` comes from change `<other-id>`, which is not archived yet — archive `<other-id>` first."*
- **Found nowhere at all** → now it is a real error. The delta targets a requirement that does not exist anywhere. Stop and report it.

Getting this distinction wrong turns an ordinary out-of-order archive into a false accusation that the delta is broken.

### 4. A merge must not shrink a requirement

For each `MODIFIED` requirement, merge it **in memory** and compare with the version in `sk/specs/`. If the result has **fewer scenarios** than the original → stop and ask.

`MODIFIED` replaces the whole requirement, which is only correct because the delta is supposed to restate it in full, untouched scenarios included (see `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`). A delta carrying only the changed scenario deletes the others silently — names match, no conflict is raised. This check catches the common form of that mistake.

Say plainly that it is a net and not a proof: a delta that swaps one scenario for another keeps the count the same and passes. If anything about the delta looks partial, ask even when the count is fine.

### 5. Two deltas must not contradict each other

If two unarchived changes touch the same requirement in incompatible ways — both `MODIFIED` it differently, or one `MODIFIED` what another `REMOVED` — **stop and ask. Do not reconcile them yourself.**

There is no way to resolve this correctly on your own: `change-id` carries no ordering, so there is no "later one wins" to fall back on and no replay order to reconstruct. Show both sides and let the user decide.

## Phase 2 — Merge, then move

Only once every check above has passed, for every capability.

For each capability:

- **`ADDED`** — append the requirement to `sk/specs/<capability>/spec.md`. Create the file and its directory if this is the capability's first requirement
- **`MODIFIED`** — replace the whole matching requirement with the delta's version
- **`REMOVED`** — delete the matching requirement

Keep the rest of the file untouched: do not reorder requirements, do not reformat, do not tidy. A merge diff should show only what the change actually changed.

Then move `sk/changes/<id>/` to `sk/changes/archive/<id>/`, contents unchanged. Prefer `git mv` so the move is recorded as a move.

**If no shell is available**, write the change's files into `sk/changes/archive/<id>/` and then **tell the user explicitly that the original under `sk/changes/<id>/` still exists and they need to delete it.** Never leave a half-move unreported — a duplicate change directory will be picked up as an open change by `/sk:apply` and `/sk:archive` alike.

## Step 3 — Close out

Report per capability: which requirements were added, modified, removed; where the change now lives; and anything the user still has to do by hand.

Azure DevOps is not touched. Updating the work item's state is a person's job.

## Guardrails

- Validate every capability before writing any file
- `ADDED` onto an existing name → stop and ask
- `MODIFIED`/`REMOVED` with no target → check unarchived deltas before calling it an error
- Fewer scenarios after merge → stop and ask
- Contradicting deltas → stop and ask, never reconcile
- Never reorder or reformat `sk/specs/` beyond the requirement being changed
- Report an incomplete move; never let it pass silently
- No Azure DevOps writes
