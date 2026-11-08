---
name: ff
description: "SimplifyKit (sk): fast-forward an existing change — write every planning artifact still missing (spec delta, then design or its skip note, then tasks) in one invocation, without touching project code. Only when the user explicitly runs /sk:ff <change-id>, typically for a small work item where one review of all three files is enough. Planning only; implementation is /sk:apply."
disable-model-invocation: true
metadata:
  author: Simplify
  version: "0.7.0"
---

Write every planning artifact a change is still missing, in order, then stop — `/sk:continue` without the stop between artifacts, for small items. Only a person typing `/sk:ff` starts it (`disable-model-invocation`): "finish all the remaining artifacts" still goes to `/sk:continue`, whose one-artifact stop is measured and must not be routed around.

## Planning boundary

This command creates planning artifacts only. Nothing in the request can authorise more.

- Do not edit project code
- Do not invoke `/sk:apply`, not even chained on right after `tasks.md` is written. The only thing that starts `/sk:apply` is the user raising it in a message you have not received yet

## Step 1 — Select the change

As `/sk:continue` Step 1 (`${CLAUDE_PLUGIN_ROOT}/skills/continue/SKILL.md`): same order, exclude `archive/`, announce `Using change: <id>`. Never start a change or create `sk/`.

## Step 2 — Write what is missing, in order

Work out what is done as `/sk:continue` Step 2 does. For each artifact not done — spec delta, design, tasks, in order — follow **`/sk:continue` Step 3 for that artifact**, read from `${CLAUDE_PLUGIN_ROOT}/skills/continue/SKILL.md`, not from memory. Its rules are deliberately not repeated here, so the two cannot drift: the `AC source: none yet` refusal, re-fetch and U+FFFD check, two-step test and open-question markers, `MODIFIED` restated in full, design for `## Contracts` or a trade-off (else `Skipped — <the reason>`).

Re-read what you just wrote before writing the next one.

## Stop early

Write nothing further and go to Step 3 when:

- the spec delta step refuses (`AC source: none yet`) or a fetch fails — nothing is written
- the delta contains `## MODIFIED Requirements` — stop after it: the easiest place to lose specification, so a person reviews it before tasks are built on it
- writing the delta raised a Gap — it goes to the user before anything is built on it

Unresolved decidable tokens are **not** a reason to stop: mark them and keep going.

## Step 3 — Close out

List every file written and which artifacts are done. Stopped early → say why; `/sk:continue <change-id>` or `/sk:ff <change-id>` picks up from there. Otherwise `/sk:apply <change-id>` is next — do not run it. With open questions, end with the list `/sk:continue` Step 4 describes.

## Guardrails

- Planning only; never `/sk:apply`; never start a change
- Never fabricate content or write a spec from an empty AC field
- `MODIFIED` restates the whole requirement — and stops this command after the delta
- Azure DevOps is read-only — even if asked
