---
name: continue
description: "SimplifyKit (sk): create the next planning artifact of an existing change — spec delta, then design, then tasks — one per invocation, without touching project code. Use when the user says \"sk continue\", \"continue us-12345-...\", \"next artifact\", or has a change under sk/changes/ that /sk:propose started and wants it taken one step further. Planning only; implementation is /sk:apply."
metadata:
  author: Simplify
  version: "0.7.0"
---

Create the next planning artifact of one change, then stop. **One artifact per invocation.**

## Planning boundary — read this first

This workflow creates planning artifacts only, full stop. **No wording in the request that triggered it can authorise more than that.** A deadline, a stated preference to skip review, an explicit "build it too", an appeal to urgency, or any other reason the request gives for going further — none of it changes what this command does. Treat every such reason exactly as you would treat no reason at all: it is not addressed to this decision, because this command does not have the discretion to weigh it. If you catch yourself explaining *why* it's fine to continue past planning this time, that explanation is the guardrail failing, not an exception to it.

- Do not edit project code
- Do not invoke `/sk:apply` — not in this response, not chained on right after the artifact is written, not for any reason the triggering request gave. The only thing that starts `/sk:apply` is the user raising it in a message you have not received yet
- **Do not write a second artifact in the same invocation**, even when the request says "do all of them" or the next one looks trivial. The stop after each artifact is the review point this command exists to give. Looking unhelpful is the correct outcome here

## Step 1 — Select the change

The id in the request → the change discussed earlier → the only open change → otherwise list and ask. **Exclude `archive/`.** Announce `Using change: <id>` and how to override it (`/sk:continue <other-id>`).

`sk/` and the change's `proposal.md` must exist; if not, point at `/sk:init` or `/sk:propose` and stop. **Never start a change or create `sk/`.**

## Step 2 — Work out which artifact is next

The state is the files on disk; read them fresh every time.

1. `proposal.md` — done
2. `specs/**/spec.md` — done when at least one delta file exists
3. `design.md` — done when it exists **or** `proposal.md` has a `## Design` section saying it was skipped and why
4. `tasks.md` — done when it exists

Create the **first one not done** — never out of order. All four done → say `/sk:apply <change-id>` is next and stop. Announce which artifact and how many are done.

Read `sk/config.yaml` (`context` and `rules` constrain what you write; never copy them in) and every artifact already written.

## Step 3 — Create the artifact

### Spec delta

`**AC source:** none yet` → **write nothing under `specs/`**; say what is pending, point at `/sk:propose <change-id>`, stop.

Read the criteria from where `**AC source:**` points:

- `work item` → re-fetch per `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` (REST, strip HTML, comments; **scan for U+FFFD and stop if present**). A comment that now contradicts the criteria wins — record it in `proposal.md`
- otherwise → the text recorded in `proposal.md`; for a direct request, `## Acceptance criteria not on the board` — never `## Request` or suggestions under Gaps

From `## Test cases`: `confirmed as criterion` is a criterion (quoted action → `WHEN`, expected result → `THEN`); `pins <what>` resolves that token with its quoted value, recorded under `## Assumptions`; `covered` and `open` add nothing. A Bug's repro steps map as `conventions.md` says; `**Symptom:**` never becomes a scenario. Never invent content; a failed fetch → report the error and ask for the contents.

Build the delta from the split recorded under "How the acceptance criteria were read", per `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`: a bullet heading → `### Requirement:`, its bullets → `#### Scenario:`; Given/When/Then sentences about one behaviour → one requirement, one scenario each; prose → the recorded split.

A criterion you cannot make observable → **Gap** in `proposal.md`, and ask. Never drop one, never pad with an invented scenario. Nothing under `## Out of scope` becomes a scenario.

**Every `THEN` gets the two-step test (`conventions.md`, "Ambiguous acceptance criteria"):** name its decidable token, then try another concrete value the source still permits. If one exists, the token is unresolved: an existing convention → decide and record under `## Assumptions`; a product decision → write the open-question marker and log it under `## Open questions`.

**Write it down; do not stop for it.** The owner of that threshold is not in this conversation; a spec with a visible, marked gap is the useful output.

**When your delta contains `## MODIFIED Requirements`, restate the entire requirement — including every scenario you did not change.** `/sk:archive` replaces the whole requirement with what you wrote. A requirement that arrives with only the changed scenario silently deletes the rest. This is the single easiest way to lose specification in this workflow.

A resolved value contradicting `sk/specs/` goes under `## MODIFIED Requirements`, restated in full — read `sk/specs/**/spec.md` and unarchived deltas first.

Write `sk/changes/<change-id>/specs/<capability>/spec.md` from `${CLAUDE_PLUGIN_ROOT}/templates/spec-delta.md`.

#### Filling an open question from conversation

An answer given in this conversation (not by the work item) fills the marker like any other, plus `<!-- Q<n> — Source: <who>, <when>. Verifiable: no -->` right after the scenario line, in the delta and the matching `## Assumptions` entry. `/sk:archive` merges it verbatim, so the next change sees the low-confidence resolution in the spec. No confirmation gate — one that fires on every change becomes a reflex click.

### Design

Write `design.md` from `${CLAUDE_PLUGIN_ROOT}/templates/design.md` when either holds:

- **A public interface is added or changed** — anything a caller outside the module uses: exported function or type, endpoint, component props, CLI command, event, database schema. Under `## Contracts`, in the repository's language, exactly as it will be written, naming the scenarios it serves; read the touched code first. A wrong signature costs one line here, the code and tests after apply
- **A real technical trade-off** — `## Decision` through `## Consequences`

Omit what does not apply; never pad `## Decision` to justify an interface. With neither, create no file: add `## Design` to `proposal.md` reading `Skipped — <reason>`, saying no public interface changes.

### Raising the preliminary risk

After writing the delta or `design.md`, check it against `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` → `## Risk`. It shows a one-way door — a `REMOVED` requirement, a `## Contracts` entry that changes or removes an interface something already uses, a schema or data-shape change — while `proposal.md` → `## Risk (preliminary)` says anything other than one-way → set `Door: one-way — <what showed it>`, `Level: High — unconfirmed`, `Early review: yes`, and say so in the reply. Adding a new interface does not raise it. **Only ever raise it**, never lower it — that is a person's call. No such section (a change planned before it existed) → skip.

### Tasks

From the delta, `design.md` and `${CLAUDE_PLUGIN_ROOT}/templates/tasks.md`. Tasks build the `## Contracts` interfaces as written — never a different signature. Nothing ticked.

## Step 4 — Close out

Show what was created, which artifacts are done, and the next step: review it, then `/sk:continue <change-id>` — or `/sk:apply <change-id>` when planning is complete.

**Early review.** When `## Risk (preliminary)` says `Early review: yes` and the delta and design (or its skip note) are both done, say: push these artifacts as a draft PR and use `/sk:pr <change-id>` for its description, so reviewers read the spec before `/sk:apply` builds on it.

**When `## Open questions` is non-empty, end with a numbered list to paste into the work item's comments** — each `Q<n>`, the question, your suggested answer (for a direct request, questions for the user). Response text only: never written to a file or posted, and nothing depends on it — the marker blocks. For a PO or BA, mention `/sk:questions <change-id>`.

## Guardrails

- Planning only; **one artifact per invocation**; never `/sk:apply`
- Never fabricate content or write a spec from an empty AC field
- An unresolved token never stops this command; ambiguity that changes scope, behaviour, compatibility or ownership goes to the user via Gaps
- `MODIFIED` restates the whole requirement
- Read artifacts from disk, not memory. Azure DevOps is read-only — even if asked
