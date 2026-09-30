---
name: archive
description: "SimplifyKit (sk): close a finished change — merge its spec delta into the living spec under sk/specs/, record its design decision as an ADR and its new terms in sk/context.md, and move the change into sk/changes/archive/. Use when the user says \"sk archive\", \"archive the change\", or a change's tasks are all complete and its requirements should become part of the project's specification. Also \"sk archive backfill\", or an id that is already archived: writes the ADR and glossary records for changes archived earlier, without merging or moving anything."
metadata:
  author: Simplify
  version: "0.2.0"
---

Merge a finished change's spec delta into `sk/specs/`, record what the merge alone would lose (an ADR, glossary terms), then move the change into `sk/changes/archive/`.

This is the only SimplifyKit command that overwrites and moves things. So it runs in two phases: **validate everything first, write nothing until every check passes.** A merge that stops halfway leaves `sk/specs/` partly updated with the change still in place, and rerunning it merges the same requirements twice.

## Step 1 — Select the change

Same as `/sk:apply`: the id in the request → the one under discussion → the only open change → otherwise list and ask. Exclude `archive/` when listing. Announce `Archiving change: <id>`.

**Two requests are not an archive at all — go straight to [Records mode](#records-mode) and skip Phase 1 and Phase 2:**

- the id names a change that already sits under `sk/changes/archive/`. Re-running the merge would only report that everything is already there, which helps nobody, so the useful thing left to do for it is its records. The request does not need to say "ADR" or "glossary": an already-archived id *is* the request
- the request says `backfill`, or asks for the records of every archived change (`/sk:archive backfill`). It covers every directory under `sk/changes/archive/`

This is a real observed failure, not a hypothetical: `/sk:archive <id>` on an archived change validated, found the spec already merged, stopped with "already archived", and only offered to read the proposal if asked.

## Phase 1 — Validate. Write nothing.

Read `sk/changes/<id>/tasks.md`, `proposal.md`, `design.md` if present, every `sk/changes/<id>/specs/**/spec.md`, the existing `sk/adr/` and `sk/context.md` if any, the matching `sk/specs/<capability>/spec.md` for each capability the change touches, and `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` — it defines the open-question marker check 2 below looks for. Then run **all** of the checks below across **all** capabilities before writing anything. Collect every problem and report them together — do not fix one, write, and discover the next.

### 1. Tasks are finished

Any `- [ ]` left in `tasks.md` → stop. Report which tasks are open and point at `/sk:apply`.

### 2. No open questions remain in the delta

Any scenario in `sk/changes/<id>/specs/**/spec.md` still carrying the open-question marker (`reference/conventions.md`) → stop. Write nothing, move nothing. Report exactly which question is still open — its `Q<n>` and the scenario it sits in, taken from `proposal.md`'s `## Open questions` — so the person resolving it knows precisely what to answer.

This runs right after check 1, before any of the merge-shape checks below, because it is the cheapest check here and the one with the heaviest consequence if skipped: a marker that reaches `sk/specs/` stops being a flagged gap and becomes indistinguishable from a normal requirement — this is the one-way door the whole marker exists to keep shut.

### 3. `ADDED` must not already exist

A requirement under `## ADDED Requirements` whose name already appears in `sk/specs/<capability>/spec.md` → **stop and ask**. Merging it produces two requirements with the same name and nothing to distinguish them. The user decides whether it should have been `MODIFIED`, or whether one of them needs renaming.

### 4. `MODIFIED` / `REMOVED` must have a target — and "missing" has two meanings

A requirement under `## MODIFIED Requirements` or `## REMOVED Requirements` that is not in `sk/specs/<capability>/spec.md`: **before concluding anything, search the other changes' deltas** — `sk/changes/*/specs/<capability>/spec.md`, excluding `archive/`.

- **Found in another change that has not been archived yet** → this is an ordering matter, not a mistake. That change introduced the requirement and this one builds on it; `/sk:propose` is *supposed* to read unarchived deltas. Stop with: *"`<requirement>` comes from change `<other-id>`, which is not archived yet — archive `<other-id>` first."*
- **Found nowhere at all** → now it is a real error. The delta targets a requirement that does not exist anywhere. Stop and report it.

Getting this distinction wrong turns an ordinary out-of-order archive into a false accusation that the delta is broken.

### 5. A merge must not shrink a requirement

For each `MODIFIED` requirement, merge it **in memory** and compare with the version in `sk/specs/`. If the result has **fewer scenarios** than the original → stop and ask.

`MODIFIED` replaces the whole requirement, which is only correct because the delta is supposed to restate it in full, untouched scenarios included (see `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`). A delta carrying only the changed scenario deletes the others silently — names match, no conflict is raised. This check catches the common form of that mistake.

Say plainly that it is a net and not a proof: a delta that swaps one scenario for another keeps the count the same and passes. If anything about the delta looks partial, ask even when the count is fine.

### 6. Two deltas must not contradict each other

If two unarchived changes touch the same requirement in incompatible ways — both `MODIFIED` it differently, or one `MODIFIED` what another `REMOVED` — **stop and ask. Do not reconcile them yourself.**

There is no way to resolve this correctly on your own: `change-id` carries no ordering, so there is no "later one wins" to fall back on and no replay order to reconstruct. Show both sides and let the user decide.

## Between the phases — Draft the record that outlives the change

Only once every check above has passed. **Still writes nothing.**

`sk/changes/archive/` is gitignored (`/sk:init` sets that up), so once this command finishes, the merged spec is all git keeps of the change. Its `design.md` — the only place the reason for a trade-off is written down — and the terms it introduced would vanish with it. Two records are therefore written under `sk/`, both committed:

- **An ADR**, `sk/adr/NNNN-<slug>.md`, from `sk/changes/<id>/design.md`. **No `design.md`, no ADR.** With one, all three must hold or you skip it and say which failed: the decision is *hard to reverse*; it is *surprising without context* (a reader would wonder why it was done this way); it is *the result of a real trade-off* (genuine alternatives, chosen for stated reasons). Use `${CLAUDE_PLUGIN_ROOT}/templates/adr.md`. Number it one above the highest under `sk/adr/`, four digits, starting at `0001`. Say only what `design.md` says — condensed, never embellished
- **Glossary terms**, in `sk/context.md`, for terms the delta or `proposal.md` *defines* and that are specific to this project. General programming concepts and implementation detail do not belong. Use `${CLAUDE_PLUGIN_ROOT}/templates/context.md`. A term already in the file with a different meaning is a conflict: put it in the question, never overwrite. Never invent a term, and never invent an `_Avoid_` word — one needs a source where the work item actually used it

Show the draft ADR and each draft term, and ask the user in **one round** to confirm, edit or drop each. Nothing is written yet. If there is nothing to draft, say so in a line and do not ask.

**When nobody can answer** — the request says so, which is what an unattended run looks like — write neither. Merge and move as normal, and list what you skipped in Step 3 along with the full drafts as response text, so a person can apply them. Do not read silence as consent: an ADR and a glossary are the only long-lived record left once the change is archived, and they should not carry rationale nobody has seen.

Before writing an ADR, search `sk/adr/` for an existing one carrying the change id — never write a second.

## Records mode

For changes that are already archived: writes the ADR and glossary records and nothing else. **No merge, no move, no validation checks, and `sk/specs/` is not touched.**

1. Read, for each change in scope, its `proposal.md`, its spec delta and its `design.md` if present, plus the existing `sk/adr/` and `sk/context.md`
2. Draft as described in the step above, with these additions for more than one change:
   - **One glossary draft for all of them.** The same term defined the same way in several changes is one entry, listing each source change. A term defined *differently* in two changes is a conflict: put it in the questions with both wordings and their changes, never pick one
   - **An ADR per change that has a `design.md` and passes all three criteria.** For each that does not, one line saying which criterion failed or that there is no `design.md`
   - Skip any change that already has its ADR (an existing one carrying its id)
3. Ask **once** for the whole batch: confirm, edit or drop each entry. When it is long, group by capability inside that single round rather than asking repeatedly
4. Write what is confirmed, then stop

Unattended, write nothing and print the drafts, as above.

## Phase 2 — Merge, record, then move

Only once every check above has passed, for every capability, and the drafts above are confirmed or dropped.

For each capability:

- **`ADDED`** — append the requirement to `sk/specs/<capability>/spec.md`. Create the file and its directory if this is the capability's first requirement
- **`MODIFIED`** — replace the whole matching requirement with the delta's version
- **`REMOVED`** — delete the matching requirement

Keep the rest of the file untouched: do not reorder requirements, do not reformat, do not tidy. A merge diff should show only what the change actually changed.

Then write the confirmed ADR (create `sk/adr/` if this is the first) and update `sk/context.md` (create it if this is the first term), carrying the change id in each so they trace back to where they came from.

Then move `sk/changes/<id>/` to `sk/changes/archive/<id>/`, contents unchanged. How depends on whether the archive is ignored — check with `git check-ignore -q sk/changes/archive/<id>/proposal.md`:

- **Ignored** (the normal case): copy the directory into `archive/` (creating it if it does not exist), then take the original out of git with `git rm -r -q sk/changes/<id>` (plain removal if it was never tracked). **Do not `git mv`**: it stages the destination whatever `.gitignore` says, so the archived copy would be committed after all and the ignore rule would fail silently for exactly the files it exists to keep out
- **Not ignored** (a workspace set up before archives were ignored): `git mv`, as before, and say in Step 3 that archived changes are being committed here and that adding `sk/changes/archive/` to `.gitignore` stops it

**If no shell is available**, write the change's files into `sk/changes/archive/<id>/` and then **tell the user explicitly that the original under `sk/changes/<id>/` still exists and they need to delete it.** Never leave a half-move unreported — a duplicate change directory will be picked up as an open change by `/sk:apply` and `/sk:archive` alike.

## Step 3 — Close out

Report per capability: which requirements were added, modified, removed; which ADR and glossary terms were written, or skipped and why (with the drafts, when skipped); where the change now lives; and anything the user still has to do by hand.

Azure DevOps is not touched. Updating the work item's state is a person's job.

## Guardrails

- Validate every capability before writing any file
- An open question left in the delta → stop, write nothing, move nothing, name the question
- `ADDED` onto an existing name → stop and ask
- `MODIFIED`/`REMOVED` with no target → check unarchived deltas before calling it an error
- Fewer scenarios after merge → stop and ask
- Contradicting deltas → stop and ask, never reconcile
- Never reorder or reformat `sk/specs/` beyond the requirement being changed
- No ADR without a `design.md`, none unless all three criteria hold, and none written unattended; never a second ADR for the same change
- Never `git mv` into an ignored archive
- An id already under `archive/`, or `backfill`, is Records mode: no validation, no merge, no move, `sk/specs/` untouched. Never answer it with "already archived" and stop
- Report an incomplete move; never let it pass silently
- No Azure DevOps writes
