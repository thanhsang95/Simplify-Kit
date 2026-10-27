---
name: ff
description: "SimplifyKit (sk): fast-forward an existing change — write every planning artifact still missing (spec delta, then design or its skip note, then tasks) in one invocation, without touching project code. Only when the user explicitly runs /sk:ff <change-id>, typically for a small work item where one review of all three files is enough. Planning only; implementation is /sk:apply."
disable-model-invocation: true
metadata:
  author: Simplify
  version: "0.6.0"
---

Write every planning artifact a change is still missing, in order, then stop. This is `/sk:continue` without the stop between artifacts — for small items, where reviewing the delta, design note and tasks together is enough.

`disable-model-invocation` keeps this skill out of the model's reach on purpose: only a person typing `/sk:ff` starts it. A request like "finish all the remaining artifacts" still goes to `/sk:continue`, which writes one — that stop is measured by the `continue-one-artifact-per-call` eval and must not be routed around.

## Planning boundary

This command creates planning artifacts only. Nothing in the request can authorise more.

- Do not edit project code
- Do not invoke `/sk:apply`, not even chained on right after `tasks.md` is written. The only thing that starts `/sk:apply` is the user raising it in a message you have not received yet

## Step 1 — Select the change

Exactly as `/sk:continue` Step 1 in `${CLAUDE_PLUGIN_ROOT}/skills/continue/SKILL.md`: same selection order, exclude `archive/`, announce `Using change: <id>`. `sk/` and `proposal.md` must exist — this command never starts a change and never creates `sk/`.

## Step 2 — Write what is missing, in order

Work out what is done exactly as `/sk:continue` Step 2 does, from the files on disk. Then, for each artifact not done — spec delta, design, tasks, in that order, never out of order — create it by following **`/sk:continue` Step 3 for that artifact**, read from `${CLAUDE_PLUGIN_ROOT}/skills/continue/SKILL.md`. Read it; do not work from memory of it. Those rules are not repeated here so the two commands cannot drift apart: the `AC source: none yet` refusal, the work-item re-fetch and U+FFFD check, the two-step test and open-question markers, `MODIFIED` restating the entire requirement, and design written only for a real trade-off (otherwise `## Design` → `Skipped — <the reason>` in `proposal.md`).

Re-read the artifacts you just wrote before writing the next one, as `/sk:continue` would on its next invocation.

## Stop early

Write nothing further and go to Step 3 when:

- the spec delta step refuses (`AC source: none yet`) or a fetch fails — nothing is written
- the delta contains `## MODIFIED Requirements` — stop after the delta. A `MODIFIED` block replaces the living requirement whole at archive time; it is the easiest place to lose specification, so a person reviews it before tasks are built on it
- writing the delta raised a Gap — ambiguity that changes scope, observable behaviour, compatibility or which capability owns the work. That goes to the user before anything is built on it

Unresolved decidable tokens are **not** a reason to stop: mark them, as `/sk:continue` does, and keep going.

## Step 3 — Close out

List every file written in this invocation — the user reviews them together — and which of the four artifacts are now done. If you stopped early, say why and that `/sk:continue <change-id>` (or `/sk:ff <change-id>` again) picks up from there. Otherwise say planning is complete and `/sk:apply <change-id>` is next. Do not run it.

When `## Open questions` in `proposal.md` is non-empty, end with the numbered list `/sk:continue` Step 4 describes — response text only, never written to a file or posted to Azure DevOps.

## Guardrails

- Planning only. No project code is edited, and `/sk:apply` is never invoked from within this command
- Never create `sk/`, and never start a change: `proposal.md` must already exist
- Never fabricate work item content, and never generate a spec from an empty AC field
- `MODIFIED` restates the whole requirement — and stops this command after the delta
- Azure DevOps is read-only here: no comments, no new work items, no state changes — even if asked
