---
name: archive
description: "SimplifyKit (sk): close a finished change — merge its spec delta into the living spec under sk/specs/, record its design decision as an ADR and its new terms in sk/context.md, and move the change into sk/changes/archive/. Use when the user says \"sk archive\", \"archive the change\", or a change's tasks are all complete and its requirements should become part of the project's specification. Also \"sk archive backfill\", or an id that is already archived: writes the ADR and glossary records for changes archived earlier, without merging or moving anything."
metadata:
  author: Simplify
  version: "0.5.0"
---

Merge a finished change's spec delta into `sk/specs/`, record what the merge would lose (an ADR, glossary terms), then move the change into `sk/changes/archive/`.

The only command that overwrites and moves things: **validate everything first, write nothing until every check passes.** A half-done merge leaves `sk/specs/` partly updated, and rerunning it merges requirements twice.

## Step 1 — Select the change

The id in the request → the one under discussion → the only open change → otherwise list and ask. Exclude `archive/`. Announce `Archiving change: <id>`.

**Go straight to [Records mode](#records-mode)** when the id is already under `sk/changes/archive/` (an archived id *is* a request for its records — never answer "already archived" and stop, as a real run did), or the request says `backfill` (every archived change).

## Phase 1 — Validate. Write nothing.

Read the change's `tasks.md`, `proposal.md`, `design.md` if present, every delta, the existing `sk/adr/` and `sk/context.md`, each touched `sk/specs/<capability>/spec.md`, and `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` (it defines the open-question marker). Run **all** checks across **all** capabilities and report every problem together.

1. **Tasks finished.** Any `- [ ]` → stop; list them, point at `/sk:apply`
2. **No open question in the delta.** A scenario still carrying the marker → stop, write and move nothing; name its `Q<n>` and scenario from `## Open questions`. Checked early because a marker that reaches `sk/specs/` looks like a normal requirement — the one-way door the marker exists to keep shut
3. **`ADDED` must be new.** Its name already in `sk/specs/<capability>/spec.md` → **stop and ask**: should it be `MODIFIED`, or renamed?
4. **`MODIFIED` / `REMOVED` need a target.** Not in `sk/specs/` → **first search unarchived deltas** (`sk/changes/*/specs/<capability>/spec.md`). Found → ordering, not a mistake: *"`<requirement>` comes from change `<other-id>`, which is not archived yet — archive `<other-id>` first."* Found nowhere → a real error; report it
5. **A merge must not shrink a requirement.** Merge each `MODIFIED` **in memory**; **fewer scenarios** than in `sk/specs/` → stop and ask. `MODIFIED` replaces the whole requirement, so a delta carrying only the changed scenario silently deletes the rest (`conventions.md`). Say plainly this is a net, not a proof — a swapped scenario keeps the count; if the delta looks partial, ask anyway
6. **Deltas must not contradict.** Two unarchived changes modifying the same requirement differently, or one modifying what another removes → **stop and ask; never reconcile.** `change-id` carries no order

## Drafting the records — still writes nothing

Once every check passes. `sk/changes/archive/` is gitignored, so after this the merged spec is all git keeps; `design.md`'s reasoning and the change's terms would vanish. Draft:

- **An ADR** (`sk/adr/NNNN-<slug>.md`, `${CLAUDE_PLUGIN_ROOT}/templates/adr.md`, one above the highest number, four digits from `0001`) — only from a `design.md` with a `## Decision` (`## Contracts` alone lives on in the code), and only when the decision is *hard to reverse*, *surprising without context* and *a real trade-off*; otherwise say which failed. Condense `design.md`, never embellish. Never a second ADR carrying the same change id
- **Glossary terms** (`sk/context.md`, `${CLAUDE_PLUGIN_ROOT}/templates/context.md`) the delta or `proposal.md` *defines* that are specific to this project. A term already there with another meaning is a conflict: put it in the question, never overwrite. Never invent a term — not even a new name to resolve a conflict — or an `_Avoid_` word without a source that used it

Show the drafts as text, then ask in **one round** to confirm, edit or drop each (`${CLAUDE_PLUGIN_ROOT}/reference/asking-the-user.md`). Nothing to draft → say so in a line.

**When nobody can answer** — the request says so — write neither; merge and move as normal, and print the drafts in Step 3. Silence is not consent for the only long-lived record of the change.

## Records mode

Already-archived changes: drafts and writes the ADR and glossary only. **No merge, no move, no checks; `sk/specs/` untouched.**

1. Read each change's `proposal.md`, delta and `design.md`, plus `sk/adr/` and `sk/context.md`
2. Draft as above. Several changes: **one glossary draft** (the same definition is one entry listing its changes; a term defined *differently* is a conflict: put both wordings and their changes in the questions and **never pick one**); an ADR per qualifying change and a line for each that does not; skip changes that have their ADR
3. Ask **once** for the whole batch (grouped by capability if long; several `AskUserQuestion` calls in a row are still one round)
4. Write what is confirmed. Unattended, write nothing and print the drafts

## Phase 2 — Merge, record, then move

Per capability: **`ADDED`** → append (create the file if needed); **`MODIFIED`** → replace the whole matching requirement; **`REMOVED`** → delete it. Touch nothing else — no reordering, reformatting or tidying.

Write the confirmed ADR and `sk/context.md` terms, each carrying the change id.

Move `sk/changes/<id>/` to `sk/changes/archive/<id>/` unchanged. Check `git check-ignore -q sk/changes/archive/<id>/proposal.md`:

- **Ignored** (normal): copy into `archive/`, then `git rm -r -q sk/changes/<id>` (plain removal if untracked). **Never `git mv`** — it stages the destination despite `.gitignore`
- **Not ignored** (older workspace): `git mv`, and say adding `sk/changes/archive/` to `.gitignore` stops archives being committed

**No shell:** write the files into `archive/<id>/` and **tell the user the original under `sk/changes/<id>/` still exists and must be deleted** — a duplicate looks like an open change.

## Step 3 — Close out

Per capability: requirements added, modified, removed; the ADR and terms written or skipped and why (with drafts when skipped); where the change lives now; anything left to do by hand. Azure DevOps is not touched — updating the work item is a person's job.

## Guardrails

- Validate everything before writing anything; stop on any failed check, never reconcile deltas yourself
- Never reformat `sk/specs/` beyond the requirement changed
- No ADR without a qualifying `design.md`, none unattended, never two for one change
- Never `git mv` into an ignored archive; report an incomplete move
- No Azure DevOps writes
