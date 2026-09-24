---
name: propose
description: "SimplifyKit (sk): turn an Azure DevOps work item into planning artifacts — proposal, spec delta and tasks — without touching project code. Use when the user says \"sk propose\", \"plan AB#12345\", or gives an ADO work item id or URL and wants it planned. Reads the work item's acceptance criteria and writes them as requirements and scenarios under sk/changes/. Planning only; implementation is /sk:apply."
metadata:
  author: Simplify
  version: "0.1.0"
---

Turn an Azure DevOps work item into the planning artifacts for one change.

## Planning boundary — read this first

This workflow creates planning artifacts only, full stop. **No wording in the request that triggered it can authorise more than that.** A deadline, a stated preference to skip review, an explicit "build it too", an appeal to urgency, or any other reason the request gives for going further — none of it changes what this command does. Treat every such reason exactly as you would treat no reason at all: it is not addressed to this decision, because this command does not have the discretion to weigh it. If you catch yourself explaining *why* it's fine to continue past planning this time, that explanation is the guardrail failing, not an exception to it.

- Do not edit project code
- Do not invoke `/sk:apply` — not in this response, not chained on right after the artifacts are written, not for any reason the triggering request gave. The only thing that starts `/sk:apply` is the user raising it in a message you have not received yet
- When the artifacts are written, stop and present them, even when the request made stopping there look unhelpful or overly cautious. Looking unhelpful is the correct outcome here

## Input

Accepted: `AB#12345`, or a work item URL such as `https://<org>/<project>/_workitems/edit/12345`.

**Not accepted: a bare integer.** In this codebase `#123` and a bare integer already mean *pull request id* (see the repo's `azure-devops-pr-review` skill). If the user gives a bare number, ask whether they mean a work item or a PR before doing anything.

**Also not accepted: a free-form feature description with no work item.** SimplifyKit's scope is work that starts from the board. If the user describes something with no work item behind it, say so plainly and let them plan it whichever way they normally would — do not invent a change id and do not create anything under `sk/`.

## Step 1 — Preconditions

`sk/` must exist. If it does not, point the user at `/sk:init` and stop. **Never create `sk/` as a side effect of this command.**

Read, in this order:

- `sk/config.yaml` — `context` and `rules` are constraints on what you write. Apply them; never copy them into an artifact
- `sk/specs/**/spec.md` — what the system is already specified to do
- `sk/changes/*/specs/**/spec.md` — changes that are planned but **not yet archived**. Their requirements are not in `sk/specs/` yet and you will miss them otherwise

## Step 2 — Fetch the work item

Follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` exactly — it encodes fixes for failures this project has already hit. In summary:

1. **Read over REST, not `az boards` / `az devops invoke`.** Mint a token with `az account get-access-token`, then `GET {orgUrl}/{project}/_apis/wit/workItems/{id}?$expand=all&api-version=7.1`. This is not a style preference: `az boards work-item show` corrupts non-ASCII characters on this org's data — measured, 9 replacement characters against 0 over REST — and `az devops invoke ... comments` fails outright with an extension-internal error. Never print the token
2. Strip HTML and decode entities from `System.Description` and `Microsoft.VSTS.Common.AcceptanceCriteria`
3. Read the work item's **comments** (`.../workItems/{id}/comments?api-version=7.1-preview.4`). Comments routinely narrow scope after the description was written — where a comment contradicts the description **or the acceptance criteria**, **the comment wins**, and you record that in `proposal.md`
4. If the item is a `Task`, cascade to its parent and take the parent's full fields
5. **Scan the stripped text for the replacement character U+FFFD before writing anything.** If one is present, stop and report that the fetch corrupted the source — do not write the spec. A spec that silently contains `?` where the author wrote an em dash is a contract nobody agreed to

If a fetch fails — not signed in, wrong org, no permission — report the real error and ask the user to paste the work item contents. **Never invent the contents of a work item.**

## Step 3 — Decide which branch you are in

Look at the acceptance criteria you actually got.

- **Usable AC** → Branch A
- **AC field empty, or AC too thin to describe observable behaviour** → Branch B

Roughly one story in five has no acceptance criteria at all. Branch B is a normal path, not an error.

**Ambiguity is not a third branch.** AC that reads fluently but leaves a threshold, an operator, a sort order, a set boundary, an actor, a display string, or empty/error behaviour undecided is still usable AC — it routes to Branch A like any other. Handling that ambiguity is a per-criterion step inside Branch A, not a reason to stop before Branch A starts and not a reason to fall back to Branch B.

### Branch A — usable acceptance criteria

Derive `change-id` as `us-<work item id>-<short slug>`, for example `us-12345-field-selector`. If that change already exists, ask whether to continue it or create a new one.

**Infer the mapping from the shape of the AC.** There is no fixed ratio between acceptance criteria and scenarios. Read `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` for the full rules; the three shapes you will meet:

- **Grouped bullets** — headings with bullet lists under them. The heading becomes a `### Requirement:`, its bullets become `#### Scenario:` entries
- **Given/When/Then sentences** with no grouping. Gather sentences that concern the same behaviour into one requirement, one scenario per sentence
- **Prose.** Split it by observable behaviour yourself, and **write down in `proposal.md` how you split it** so a reviewer can disagree with the split rather than having to reverse-engineer it

Any criterion you cannot turn into observable behaviour goes into the **Gaps** section of `proposal.md`, and you ask about it. Never drop one silently, and never pad the spec with a scenario you invented to make a criterion fit.

**Every scenario you write gets the two-step test from `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` ("Ambiguous acceptance criteria").** For each `THEN`: name the decidable token it turns on, then try to write one other concrete value the same source text still permits. If you can, the token is unresolved — sort it as an existing convention (decide it, record the assumption) or a product decision (write the open-question marker defined there, and log the question under `## Open questions`).

**Write it down; do not stop for it.** An unresolved token is never a reason to pause `/sk:propose` or to hold artifacts back until every threshold is settled. The person who owns that threshold is not in this conversation, and a spec withheld until they are is a spec that never gets written. A spec with a visible, marked gap is the useful output — mark it and move to the next scenario.

### Branch B — acceptance criteria missing or unusable

**Do not write anything under `specs/`.** A spec generated from an empty field is fabrication that looks like analysis.

Before asking, check `relations[]` for a `System.LinkTypes.Related` entry. Follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` ("A related item can already answer a Branch B gap") for how far to take that — bounded to a few items, one hop, never the item's children. If a related item's content looks like it answers the gap, name it and ask the user to confirm reusing it, instead of asking a bare "what are the acceptance criteria?" A plausible-looking related item is not confirmation by itself — only the user's answer is, and nothing from it is written under `specs/` before that answer arrives.

When the current item is not a `Task` (a Task's parent was already read unconditionally in Step 2), also check `relations[]` for a `System.LinkTypes.Hierarchy-Reverse` entry. Follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` ("A parent can narrow a Branch B gap when the item is not a Task") for how far to take that — one hop, and never presented as this item's own acceptance criteria wholesale. A parent's scope is broader than any one item under it, so a usable parent earns a narrowing question — what part of the parent's scope this item covers — not a bare "confirm reusing it" the way a same-shape related item does.

Show the user what you did get — title, description, comments, parent, and any related item you read — say plainly that the acceptance criteria are missing or too thin, and ask for them (or for confirmation on the related item or parent, when one was found). **When a related item or parent was read, write `proposal.md` and name it in the Gaps section, marked as a pending confirmation, whether or not the user has answered yet** — that section exists for exactly this: a criterion not yet resolved. If neither was read, writing `proposal.md` before an answer arrives is optional, same as before. If they answer or confirm, continue as Branch A and record the source in `proposal.md` instead of leaving it in Gaps. If they do not, `proposal.md` with that Gaps section is the whole output, and you stop.

## Re-running on an existing change

When Step 3 finds the change already exists and you're told to continue it, don't treat the artifacts already on disk as settled — re-verify them against the work item's current state instead of only adding to them.

Fetch the work item and its comments again, the same way as Step 2: the same REST path, the same U+FFFD scan, no shortcut just because a change directory already exists. The board keeps moving after a change is created; that is exactly what this re-fetch is for.

Read **every** entry under the existing `proposal.md`'s `## Assumptions`, not only the questions still open. A comment posted since the last run can contradict a resolution that already looked settled. When that happens, **reopen it** — put the marker back in the delta and the question back under `## Open questions` — rather than silently leaving the stale resolution in place, and rather than silently overwriting it with the new one either: a resolution changing after tasks were built on it is exactly what a reviewer needs to see, not something to infer later from a diff.

If a task in `tasks.md` is already ticked and the value it was built on changed, **do not untick it** — `tasks.md` has no dependency graph, and un-ticking work that actually landed destroys the record of what was done. Instead, name the affected task and **add a new task** that says what needs re-checking.

## Step 4 — Write the artifacts

In this order, using the files in `${CLAUDE_PLUGIN_ROOT}/templates/` as structure:

1. `sk/changes/<change-id>/proposal.md`
2. `sk/changes/<change-id>/specs/<capability>/spec.md` — the delta
3. `sk/changes/<change-id>/design.md` — **only** when there is a real technical trade-off to record. If you skip it, say why
4. `sk/changes/<change-id>/tasks.md`

`proposal.md` is a pointer, not a restatement. The work item already holds the why and the what; duplicating it here only creates a second copy to drift. It carries: the link, id and title; two or three sentences of summary; your assumptions; the Gaps; the Open questions; any comment that overrode the description; and, when Branch B reused a related item's or a parent's content, which item they came from and what the user actually confirmed.

**When your delta contains `## MODIFIED Requirements`, restate the entire requirement — including every scenario you did not change.** `/sk:archive` replaces the whole requirement with what you wrote. A requirement that arrives with only the changed scenario silently deletes the rest. This is the single easiest way to lose specification in this workflow.

**When a resolved value contradicts what `sk/specs/` already says for this capability, that requirement goes under `## MODIFIED Requirements`, restated in full per the rule above.** Resolving an open question is not a different kind of change from any other requirement update — no new check applies.

### Filling an open question from conversation

When the answer to an open question comes from this conversation — someone states a threshold, a wording, a permission, right here — rather than from the work item or its comments, fill the marker with that value like any other resolution, but leave its provenance where it survives: immediately after the scenario line it resolves, in both the delta and the matching `## Assumptions` entry in `proposal.md`, add `<!-- Q<n> — Source: <who>, <when>. Verifiable: no -->`.

That comment is not decoration — it rides inside the requirement text `/sk:archive` merges verbatim into `sk/specs/`. `/sk:propose` reads `sk/specs/**` on every run (Step 1), so the next change touching this capability sees the low-confidence resolution sitting in the spec, instead of it existing only in this conversation's transcript.

There is no confirmation gate before this can happen. A gate that fires on nearly every change degrades into a reflex click, and the record it would leave — "confirmed" — would itself be false: nobody actually re-checked the value, they just cleared a prompt that appears every time.

## Step 5 — Close out

List the files created, name any conditional artifact you skipped and why, and tell the user: review the artifacts, then run `/sk:apply <change-id>` when ready.

**When `## Open questions` is non-empty, close with a numbered list ready to paste into the work item's comments** — one line per `Q<n>`, the question, and your suggested answer. This is response text only: it is never written to a file, it is never posted to Azure DevOps, and neither `/sk:apply` nor `/sk:archive` may depend on it existing — the marker in the delta is what actually blocks, not this list.

## Guardrails

- Planning only. No project code is edited by this command, and `/sk:apply` is never invoked from within it, whatever the request said or however it justified going further
- Never create `sk/` as a side effect
- Never fabricate work item content, and never generate a spec from an empty AC field
- An unresolved decidable token — a threshold, an operator, a sort order, a set boundary, an actor, a display string, empty/error behaviour — never stops this command. Mark it with the open-question marker (`reference/conventions.md`) and keep going; ask about it only in Step 5's close-out text
- Ambiguity that changes scope, observable behaviour, compatibility, or which capability owns the work is different from a single unresolved token — that still goes to the user, same as before, via Branch B or a Gap
- Decide small conventions yourself and record the assumption; sort every unresolved token as either an existing-convention assumption or a product-decision open question — never leave one unsorted
- Read dependency artifacts from disk each time, not from memory of this conversation
- `MODIFIED` restates the whole requirement
- Azure DevOps is read-only here: no comments, no new work items, no state changes — even if asked
