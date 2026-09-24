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
3. Read the work item's **comments** (`.../workItems/{id}/comments?api-version=7.1-preview.4`). Comments routinely narrow scope after the description was written — where a comment contradicts the description, **the comment wins**, and you record that in `proposal.md`
4. If the item is a `Task`, cascade to its parent and take the parent's full fields
5. **Scan the stripped text for the replacement character U+FFFD before writing anything.** If one is present, stop and report that the fetch corrupted the source — do not write the spec. A spec that silently contains `?` where the author wrote an em dash is a contract nobody agreed to

If a fetch fails — not signed in, wrong org, no permission — report the real error and ask the user to paste the work item contents. **Never invent the contents of a work item.**

## Step 3 — Decide which branch you are in

Look at the acceptance criteria you actually got.

- **Usable AC** → Branch A
- **AC field empty, or AC too thin to describe observable behaviour** → Branch B

Roughly one story in five has no acceptance criteria at all. Branch B is a normal path, not an error.

### Branch A — usable acceptance criteria

Derive `change-id` as `us-<work item id>-<short slug>`, for example `us-12345-field-selector`. If that change already exists, ask whether to continue it or create a new one.

**Infer the mapping from the shape of the AC.** There is no fixed ratio between acceptance criteria and scenarios. Read `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` for the full rules; the three shapes you will meet:

- **Grouped bullets** — headings with bullet lists under them. The heading becomes a `### Requirement:`, its bullets become `#### Scenario:` entries
- **Given/When/Then sentences** with no grouping. Gather sentences that concern the same behaviour into one requirement, one scenario per sentence
- **Prose.** Split it by observable behaviour yourself, and **write down in `proposal.md` how you split it** so a reviewer can disagree with the split rather than having to reverse-engineer it

Any criterion you cannot turn into observable behaviour goes into the **Gaps** section of `proposal.md`, and you ask about it. Never drop one silently, and never pad the spec with a scenario you invented to make a criterion fit.

### Branch B — acceptance criteria missing or unusable

**Do not write anything under `specs/`.** A spec generated from an empty field is fabrication that looks like analysis.

Before asking, check `relations[]` for a `System.LinkTypes.Related` entry. Follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` ("A related item can already answer a Branch B gap") for how far to take that — bounded to a few items, one hop, never the item's children. If a related item's content looks like it answers the gap, name it and ask the user to confirm reusing it, instead of asking a bare "what are the acceptance criteria?" A plausible-looking related item is not confirmation by itself — only the user's answer is, and nothing from it is written under `specs/` before that answer arrives.

Show the user what you did get — title, description, comments, parent, and any related item you read — say plainly that the acceptance criteria are missing or too thin, and ask for them (or for confirmation on the related item, when one was found). **When a related item was read, write `proposal.md` and name it in the Gaps section, marked as a pending confirmation, whether or not the user has answered yet** — that section exists for exactly this: a criterion not yet resolved. If no related item was read, writing `proposal.md` before an answer arrives is optional, same as before. If they answer or confirm, continue as Branch A and record the source in `proposal.md` instead of leaving it in Gaps. If they do not, `proposal.md` with that Gaps section is the whole output, and you stop.

## Step 4 — Write the artifacts

In this order, using the files in `${CLAUDE_PLUGIN_ROOT}/templates/` as structure:

1. `sk/changes/<change-id>/proposal.md`
2. `sk/changes/<change-id>/specs/<capability>/spec.md` — the delta
3. `sk/changes/<change-id>/design.md` — **only** when there is a real technical trade-off to record. If you skip it, say why
4. `sk/changes/<change-id>/tasks.md`

`proposal.md` is a pointer, not a restatement. The work item already holds the why and the what; duplicating it here only creates a second copy to drift. It carries: the link, id and title; two or three sentences of summary; your assumptions; the Gaps; any comment that overrode the description; and, when Branch B reused a related item's acceptance criteria, which item they came from.

**When your delta contains `## MODIFIED Requirements`, restate the entire requirement — including every scenario you did not change.** `/sk:archive` replaces the whole requirement with what you wrote. A requirement that arrives with only the changed scenario silently deletes the rest. This is the single easiest way to lose specification in this workflow.

## Step 5 — Close out

List the files created, name any conditional artifact you skipped and why, and tell the user: review the artifacts, then run `/sk:apply <change-id>` when ready.

## Guardrails

- Planning only. No project code is edited by this command, and `/sk:apply` is never invoked from within it, whatever the request said or however it justified going further
- Never create `sk/` as a side effect
- Never fabricate work item content, and never generate a spec from an empty AC field
- Ask about ambiguity that changes scope, observable behaviour, compatibility, or acceptance; decide small details yourself and record the assumption
- Read dependency artifacts from disk each time, not from memory of this conversation
- `MODIFIED` restates the whole requirement
- Azure DevOps is read-only here: no comments, no new work items, no state changes — even if asked
