---
name: apply
description: "SimplifyKit (sk): implement the tasks of a planned change under sk/changes/, test-first per spec scenario, ticking each task off as its specified behaviour lands. Use when the user says \"sk apply\", \"apply the change\", \"implement us-12345-...\", or wants to start or continue building a change that /sk:propose and /sk:continue already planned."
metadata:
  author: Simplify
  version: "0.11.0"
---

Implement the tasks of one change under `sk/changes/`.

## Step 1 — Select the change

In order: the id given in the request → the change discussed earlier in this conversation → the only open change, if there is exactly one → otherwise list what is available and ask. When listing `sk/changes/`, **exclude `archive/`** — a container for finished changes, not a change.

Announce `Using change: <id>` and how to override it (`/sk:apply <other-id>`).

## Step 2 — Load the change from disk

Read from disk, even if seen earlier — the user may have edited them:

- `sk/changes/<id>/proposal.md`
- `sk/changes/<id>/specs/**/spec.md`
- `sk/changes/<id>/design.md`, if present
- `sk/changes/<id>/tasks.md`
- `sk/config.yaml` — its `context` and `rules` apply while you implement; its `Test:` line is the test command
- `${CLAUDE_PLUGIN_ROOT}/reference/tdd.md` — how each scenario gets its test

No tasks → point at `/sk:continue <id>` (or `/sk:propose`) and stop. Never improvise a task list: a human approved this one.

## Step 3 — Report where you are

Show the change id, progress as `N/M tasks complete`, and what remains.

If the repository has no test setup (as `tdd.md` defines it) and a person can answer, ask now, once, how they want tests handled — not per task.

## Step 4 — Work the list

Test first: each `#### Scenario` gets a test from it before its code, seen failing for the right reason, then passing (`tdd.md` has the loop and its exceptions: no shell, no test setup, nothing testable). The test is a step inside the task, not a new task.

For each unchecked task:

1. Say which task you are on
2. Write the failing test for each scenario this task is the first to touch, and run it when a shell is available
3. Make the change the task calls for, and no more
4. Run those tests again, when a shell is available
5. Tick it — `- [ ]` → `- [x]` — immediately, in `tasks.md`
6. Move to the next

**Only tick a task when its specified behaviour actually works** — not partly done, not with the hard half deferred, not a simpler version. A ticked box is a claim others rely on. When the test could run, working means it passes (except a task starting a scenario spread over several, `tdd.md`); a test that will not pass is a blocker, never a reason to loosen it.

**A scenario still carrying the open-question marker** (`${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`): **build against the reading under that question's `## Assumptions` entry**, tick as usual, and note it: `- [x] 2.1 <task>  (built on Q3)` — so whoever resolves `Q3` finds every task that assumed an answer.

`/sk:apply` does not block on open questions — only `/sk:archive` does. The asymmetry is deliberate: archive already locks that door, and `tasks.md` has no dependency graph to tell which tasks could proceed without the answer, so refusing to tick any would stall the whole checklist on one open threshold.

**Stop and ask** when:

- A task is ambiguous — ask rather than pick a reading
- The design has a hole — say so and suggest updating the artifacts. A `## Contracts` interface that cannot be built as written is one: never ship a different signature on your own
- A task needs work beyond the spec, or you want to narrow, defer or except specified behaviour. **Surface the extra scope; never absorb it.** If it is under `## Out of scope`, name the entry and its source
- Anything errors or blocks

## Step 5 — Close out

Report tasks completed this session and overall progress. **Name every task ticked with a `(built on Q<n>)` note**, so whoever resolves that open question can see exactly what assumed the reading they're about to overturn.

Report the tests: which scenarios got one and whether you saw it fail then pass; tests written but **not run**, and why; scenarios without a test, and why; test-first skipped for lack of a setup. For a Bug, whether the failure matched `**Symptom:**`, and the cause in one line (`tdd.md`, "A change from a Bug"). Never report a run that did not happen. Suggest running the full suite `sk/config.yaml` records.

All ticked → next is `/sk:verify <change-id>` (recommended, read-only), then `/sk:archive`.

## Guardrails

- Keep going until done or genuinely blocked; read the artifacts from disk before starting
- Tick immediately, and only for behaviour that actually works
- Test each scenario before its code; never claim a test run you did not make, never install a test framework, never weaken a test to make it pass
- Keep each edit scoped to the task; pause on ambiguity, blockers and scope growth — do not guess and do not quietly shrink the work
- Open questions do not block: build on the recorded reading and note `(built on Q<n>)`
- Do not touch Azure DevOps
