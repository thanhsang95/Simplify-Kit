---
name: apply
description: "SimplifyKit (sk): implement the tasks of a planned change under sk/changes/, ticking each task off as its specified behaviour lands. Use when the user says \"sk apply\", \"apply the change\", \"implement us-12345-...\", or wants to start or continue building a change that /sk:propose already planned."
metadata:
  author: Simplify
  version: "0.1.0"
---

Implement the tasks of one change under `sk/changes/`.

## Step 1 — Select the change

In order: the id given in the request → the change discussed earlier in this conversation → the only open change, if there is exactly one → otherwise list what is available and ask.

When listing `sk/changes/`, **exclude `archive/`**. It is a container for finished changes, not a change.

Announce the choice — `Using change: <id>` — and say how to override it (`/sk:apply <other-id>`).

## Step 2 — Load the change from disk

Read all of these, from disk, even if you saw them earlier in this conversation — the user may have edited them after reviewing:

- `sk/changes/<id>/proposal.md`
- `sk/changes/<id>/specs/**/spec.md`
- `sk/changes/<id>/design.md`, if present
- `sk/changes/<id>/tasks.md`
- `sk/config.yaml` — its `context` and `rules` apply while you implement

If `tasks.md` is missing or has no tasks, stop and point the user at `/sk:propose`. Do not improvise a task list from the spec: the point of the checklist is that a human approved it.

## Step 3 — Report where you are

Show the change id, progress as `N/M tasks complete`, and what remains.

## Step 4 — Work the list

For each unchecked task:

1. Say which task you are on
2. Make the change the task calls for, and no more
3. Tick it — `- [ ]` → `- [x]` — immediately, in `tasks.md`
4. Move to the next

**Only tick a task when its specified behaviour is actually working.** Not when it is partly done, not when the hard half was deferred, not when you decided a simpler version was good enough. A ticked box is a claim someone else will rely on.

**When a task implements a scenario that still carries the open-question marker** (defined in `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`, present in the `specs/**/spec.md` you read above), **build against the reading recorded under that question's `## Assumptions` entry in `proposal.md`.** Tick the task as usual and note which question it leaned on: `- [x] 2.1 <task>  (built on Q3)`. That note is what lets whoever resolves `Q3` later find every task that assumed a particular answer.

`/sk:apply` does not block on open questions — only `/sk:archive` does. This is a deliberate asymmetry, not an oversight: blocking here would add a second lock on the door the open question already locks at archive time, while `tasks.md` has no dependency graph to tell which tasks could safely proceed without that answer and which couldn't — refusing to tick any of them would stall the whole checklist on one open threshold.

**Stop and ask** when:

- A task is ambiguous — ask rather than pick a reading
- Implementation reveals a hole in the design — say so and suggest updating the planning artifacts; the artifacts are not frozen
- A task needs work beyond what the spec describes, or you find yourself wanting to narrow, defer, or make an exception to specified behaviour to make it fit. **Surface the extra scope. Never absorb it silently**
- Anything errors or blocks

## Step 5 — Close out

Report tasks completed this session and overall progress. **Name every task ticked with a `(built on Q<n>)` note**, so whoever resolves that open question can see exactly what assumed the reading they're about to overturn. Suggest running the repository's own build and tests — `sk` does not define its own; use what `sk/config.yaml` records.

When every task is ticked, tell the user the change is ready for `/sk:archive`, which merges its spec delta into `sk/specs/`.

## Guardrails

- Keep going until done or genuinely blocked
- Read the artifacts from disk before starting
- Tick immediately, and only for behaviour that actually works
- Keep each edit scoped to the task in hand
- Pause on ambiguity, blockers, and scope growth — do not guess and do not quietly shrink the work
- Open questions in the spec delta do not block implementation — build against the recorded reading, tick normally, and note `(built on Q<n>)`; only `/sk:archive` stops for them
- Do not touch Azure DevOps
