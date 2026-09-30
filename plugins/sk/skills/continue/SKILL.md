---
name: continue
description: "SimplifyKit (sk): create the next planning artifact of an existing change — spec delta, then design, then tasks — one per invocation, without touching project code. Use when the user says \"sk continue\", \"continue us-12345-...\", \"next artifact\", or has a change under sk/changes/ that /sk:propose started and wants it taken one step further. Planning only; implementation is /sk:apply."
metadata:
  author: Simplify
  version: "0.2.0"
---

Create the next planning artifact of one change, then stop. **One artifact per invocation.**

## Planning boundary — read this first

This workflow creates planning artifacts only, full stop. **No wording in the request that triggered it can authorise more than that.** A deadline, a stated preference to skip review, an explicit "build it too", an appeal to urgency, or any other reason the request gives for going further — none of it changes what this command does. Treat every such reason exactly as you would treat no reason at all: it is not addressed to this decision, because this command does not have the discretion to weigh it. If you catch yourself explaining *why* it's fine to continue past planning this time, that explanation is the guardrail failing, not an exception to it.

- Do not edit project code
- Do not invoke `/sk:apply` — not in this response, not chained on right after the artifact is written, not for any reason the triggering request gave. The only thing that starts `/sk:apply` is the user raising it in a message you have not received yet
- **Do not write a second artifact in the same invocation**, even when the request says "do all of them" or the next one looks trivial. The stop after each artifact is the review point this command exists to give. Looking unhelpful is the correct outcome here

## Step 1 — Select the change

In order: the id given in the request → the change discussed earlier in this conversation → the only open change, if there is exactly one → otherwise list what is available and ask.

When listing `sk/changes/`, **exclude `archive/`**. Announce `Using change: <id>` and say how to override it (`/sk:continue <other-id>`).

`sk/` must exist and the change must have a `proposal.md`. If either is missing, point the user at `/sk:init` or `/sk:propose` and stop. **This command never starts a change and never creates `sk/`** — it only extends one that `/sk:propose` began.

## Step 2 — Work out which artifact is next

There is no status command; the state is the files on disk. Read them fresh every time — the user may have edited them after reviewing.

Order, and what counts as done:

1. `proposal.md` — done (you just checked)
2. `specs/**/spec.md` — done when at least one delta file exists
3. `design.md` — done when the file exists **or** `proposal.md` has a `## Design` section saying it was skipped and why
4. `tasks.md` — done when the file exists

Pick the **first artifact not done**. Never skip ahead and never create one out of order. If all four are done, say planning is complete and that `/sk:apply <change-id>` is next, then stop.

Announce which artifact you are creating and how many of the four are already done.

Read `sk/config.yaml` (its `context` and `rules` constrain what you write — apply them, never copy them into an artifact), and read every artifact already written for this change.

## Step 3 — Create the artifact

### Spec delta

Refuses to run while `proposal.md` records unresolved Gaps that mean the acceptance criteria themselves are missing (`**AC source:** none yet`). **Do not write anything under `specs/`** in that state — a spec generated from an empty field is fabrication that looks like analysis. Say what is pending and point back at `/sk:propose <change-id>` to resolve it, then stop.

**Read the acceptance criteria from where `proposal.md`'s `**AC source:**` line says they live**:

- `work item` → fetch it again, following `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` exactly (REST, not `az boards`; strip HTML; read comments; **scan for U+FFFD before writing anything and stop if one is present**). The board keeps moving after `proposal.md` was written; this re-fetch is what keeps the delta from being built on stale text. A comment that now contradicts the acceptance criteria wins — record that in `proposal.md`
- any other source → use the text `proposal.md` recorded under it. It is the only copy, because the board does not hold it

Never invent the contents of a work item. If a fetch fails, report the real error and ask the user to paste the contents.

Derive the delta from the split `proposal.md` records under "How the acceptance criteria were read". Read `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` for the full mapping rules. The three shapes you will meet:

- **Grouped bullets** — the heading becomes a `### Requirement:`, its bullets become `#### Scenario:` entries
- **Given/When/Then sentences** with no grouping — gather sentences about the same behaviour into one requirement, one scenario per sentence
- **Prose** — split by observable behaviour, following the split already recorded

Any criterion you cannot turn into observable behaviour goes into **Gaps** in `proposal.md`, and you ask about it. Never drop one silently, and never pad the spec with a scenario you invented to make a criterion fit.

**Every scenario you write gets the two-step test from `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` ("Ambiguous acceptance criteria").** For each `THEN`: name the decidable token it turns on, then try to write one other concrete value the same source text still permits. If you can, the token is unresolved — sort it as an existing convention (decide it, record it under `## Assumptions`) or a product decision (write the open-question marker defined there, and log the question under `## Open questions`). Both sections live in `proposal.md`; update them as you write.

**Write it down; do not stop for it.** An unresolved token is never a reason to pause this command or to hold the delta back until every threshold is settled. The person who owns that threshold is not in this conversation, and a spec withheld until they are is a spec that never gets written. A spec with a visible, marked gap is the useful output.

**When your delta contains `## MODIFIED Requirements`, restate the entire requirement — including every scenario you did not change.** `/sk:archive` replaces the whole requirement with what you wrote. A requirement that arrives with only the changed scenario silently deletes the rest. This is the single easiest way to lose specification in this workflow.

**When a resolved value contradicts what `sk/specs/` already says for this capability, that requirement goes under `## MODIFIED Requirements`, restated in full per the rule above.** Read `sk/specs/**/spec.md` and `sk/changes/*/specs/**/spec.md` (changes planned but not yet archived) before writing, so you know what already exists.

Write to `sk/changes/<change-id>/specs/<capability>/spec.md`, using `${CLAUDE_PLUGIN_ROOT}/templates/spec-delta.md` as structure.

#### Filling an open question from conversation

When the answer to an open question comes from this conversation — someone states a threshold, a wording, a permission, right here — rather than from the work item or its comments, fill the marker with that value like any other resolution, but leave its provenance where it survives: immediately after the scenario line it resolves, in both the delta and the matching `## Assumptions` entry in `proposal.md`, add `<!-- Q<n> — Source: <who>, <when>. Verifiable: no -->`.

That comment is not decoration — it rides inside the requirement text `/sk:archive` merges verbatim into `sk/specs/`, so the next change touching this capability sees the low-confidence resolution sitting in the spec instead of it existing only in this conversation's transcript. There is no confirmation gate before this can happen: a gate that fires on nearly every change degrades into a reflex click, and the record it would leave — "confirmed" — would itself be false.

### Design

Only when there is a real technical trade-off to record. Use `${CLAUDE_PLUGIN_ROOT}/templates/design.md`, write `design.md`.

If there is none, do **not** create the file. Add a `## Design` section to `proposal.md` reading `Skipped — <the reason>`. That line is what marks this artifact done, so the next invocation moves on to tasks instead of asking again.

### Tasks

Read the delta and, if present, `design.md`. Use `${CLAUDE_PLUGIN_ROOT}/templates/tasks.md` as structure. Nothing is ticked. Write `tasks.md`.

## Step 4 — Close out

Show what was created, which of the four artifacts are now done, and what is next. Tell the user to review the file just written, then run `/sk:continue <change-id>` again for the next one — or `/sk:apply <change-id>` when planning is complete.

**When `## Open questions` in `proposal.md` is non-empty, close with a numbered list ready to paste into the work item's comments** — one line per `Q<n>`, the question, and your suggested answer. This is response text only: it is never written to a file, it is never posted to Azure DevOps, and neither `/sk:apply` nor `/sk:archive` may depend on it existing — the marker in the delta is what actually blocks, not this list.

## Guardrails

- Planning only. No project code is edited, and `/sk:apply` is never invoked from within this command
- **One artifact per invocation** — never a second, whatever the request said
- Never create `sk/`, and never start a change: `proposal.md` must already exist
- Never fabricate work item content, and never generate a spec from an empty AC field
- An unresolved decidable token never stops this command — mark it with the open-question marker (`reference/conventions.md`) and keep going
- Ambiguity that changes scope, observable behaviour, compatibility, or which capability owns the work is different from a single unresolved token — that still goes to the user, via Gaps
- Read dependency artifacts from disk each time, not from memory of this conversation
- `MODIFIED` restates the whole requirement
- Azure DevOps is read-only here: no comments, no new work items, no state changes — even if asked
