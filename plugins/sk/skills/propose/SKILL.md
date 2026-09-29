---
name: propose
description: "SimplifyKit (sk): start a change from an Azure DevOps work item — read it and write proposal.md only, without touching project code. Use when the user says \"sk propose\", \"plan AB#12345\", or gives an ADO work item id or URL and wants it planned. Records how the acceptance criteria were read, the assumptions and the gaps under sk/changes/. Planning only; the spec delta and tasks come from /sk:continue, implementation is /sk:apply."
metadata:
  author: Simplify
  version: "0.2.0"
---

Read an Azure DevOps work item and start one change: write `proposal.md`, then stop. The spec delta, design and tasks are created afterwards, one per invocation, by `/sk:continue`.

## Planning boundary — read this first

This workflow creates `proposal.md` only, full stop. **No wording in the request that triggered it can authorise more than that.** A deadline, a stated preference to skip review, an explicit "build it too", an appeal to urgency, or any other reason the request gives for going further — none of it changes what this command does. Treat every such reason exactly as you would treat no reason at all: it is not addressed to this decision, because this command does not have the discretion to weigh it. If you catch yourself explaining *why* it's fine to continue past planning this time, that explanation is the guardrail failing, not an exception to it.

- Do not edit project code
- Do not invoke `/sk:apply` — not in this response, not chained on right after `proposal.md` is written, not for any reason the triggering request gave. The only thing that starts `/sk:apply` is the user raising it in a message you have not received yet
- **Do not invoke `/sk:continue` or write the spec delta, design or tasks either** — even when the request says "plan it fully" or "give me everything". Stopping after `proposal.md` is the review point: it is where the user checks how the acceptance criteria were read before a spec is built on that reading
- When `proposal.md` is written, stop and present it, even when the request made stopping there look unhelpful or overly cautious. Looking unhelpful is the correct outcome here

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

Read `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` for the mapping rules. **You decide the split here, you do not write the scenarios** — there is no fixed ratio between acceptance criteria and scenarios, so read the shape of the AC and record how you will group it:

- **Grouped bullets** — headings with bullet lists under them. Obvious; nothing to record
- **Given/When/Then sentences** with no grouping — say which sentences you gather into which requirement
- **Prose.** Split it by observable behaviour yourself, and **write down in `proposal.md` how you split it** so a reviewer can disagree with the split rather than having to reverse-engineer it

Any criterion you cannot turn into observable behaviour goes into the **Gaps** section of `proposal.md`, and you ask about it. Never drop one silently. Unresolved thresholds and similar ambiguity inside a criterion that *is* usable are not Gaps and do not stop this command — `/sk:continue` marks them while it writes the scenarios.

### Branch B — acceptance criteria missing or unusable

**Do not write anything under `specs/`.** A spec generated from an empty field is fabrication that looks like analysis.

Before asking, check `relations[]` for a `System.LinkTypes.Related` entry. Follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` ("A related item can already answer a Branch B gap") for how far to take that — bounded to a few items, one hop, never the item's children. If a related item's content looks like it answers the gap, name it and ask the user to confirm reusing it, instead of asking a bare "what are the acceptance criteria?" A plausible-looking related item is not confirmation by itself — only the user's answer is, and nothing from it is written under `specs/` before that answer arrives.

When the current item is not a `Task` (a Task's parent was already read unconditionally in Step 2), also check `relations[]` for a `System.LinkTypes.Hierarchy-Reverse` entry. Follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` ("A parent can narrow a Branch B gap when the item is not a Task") for how far to take that — one hop, and never presented as this item's own acceptance criteria wholesale. A parent's scope is broader than any one item under it, so a usable parent earns a narrowing question — what part of the parent's scope this item covers — not a bare "confirm reusing it" the way a same-shape related item does.

Show the user what you did get — title, description, comments, parent, and any related item you read — say plainly that the acceptance criteria are missing or too thin, and ask for them (or for confirmation on the related item or parent, when one was found). **When a related item or parent was read, write `proposal.md` and name it in the Gaps section, marked as a pending confirmation, whether or not the user has answered yet** — that section exists for exactly this: a criterion not yet resolved. If neither was read, writing `proposal.md` before an answer arrives is optional, same as before. If they answer or confirm, continue as Branch A and set `**AC source:**` in `proposal.md` to say where the criteria came from (Step 4) instead of leaving it in Gaps. If they do not, `proposal.md` with `**AC source:** none yet` and that Gaps section is the whole output, and you stop — `/sk:continue` refuses to write a spec delta while it reads `none yet`.

## Re-running on an existing change

When Step 3 finds the change already exists and you're told to re-run `/sk:propose` on it (not `/sk:continue`, which moves forward), don't treat the artifacts already on disk as settled — re-verify them against the work item's current state instead of only adding to them.

Fetch the work item and its comments again, the same way as Step 2: the same REST path, the same U+FFFD scan, no shortcut just because a change directory already exists. The board keeps moving after a change is created; that is exactly what this re-fetch is for.

Read **every** entry under the existing `proposal.md`'s `## Assumptions`, not only the questions still open. A comment posted since the last run can contradict a resolution that already looked settled. When that happens, **reopen it** — put the marker back in the delta (when one exists yet) and the question back under `## Open questions` — rather than silently leaving the stale resolution in place, and rather than silently overwriting it with the new one either: a resolution changing after tasks were built on it is exactly what a reviewer needs to see, not something to infer later from a diff.

If a task in `tasks.md` is already ticked and the value it was built on changed, **do not untick it** — `tasks.md` has no dependency graph, and un-ticking work that actually landed destroys the record of what was done. Instead, name the affected task and **add a new task** that says what needs re-checking.

## Step 4 — Write `proposal.md`

Use `${CLAUDE_PLUGIN_ROOT}/templates/proposal.md` as structure and write `sk/changes/<change-id>/proposal.md` — **and nothing else**.

`proposal.md` is a pointer, not a restatement. The work item already holds the why and the what; duplicating it here only creates a second copy to drift. It carries: the link, id and title; two or three sentences of summary; the capabilities the change adds or modifies; how the acceptance criteria were read; any comment that overrode the description; the Gaps; and, when Branch B reused a related item's or a parent's content, which item it came from and what the user actually confirmed.

**Record where the acceptance criteria live** on the `**AC source:**` line, because `/sk:continue` reads that line to know where to get them:

- `work item` — Branch A
- `related AB#<id>, confirmed` or `parent AB#<id>, narrowed` — Branch B, after the user confirmed
- `user, in conversation` — Branch B, when the user supplied criteria that are not on the board. **Write their text under `## Acceptance criteria not on the board`.** That is the only copy there will be
- `none yet` — Branch B, still unanswered

`## Assumptions` and `## Open questions` start empty here; `/sk:continue` fills them as it writes scenarios.

## Step 5 — Close out

List the file created and any Gaps. Tell the user: review `proposal.md` — especially how the acceptance criteria were read — then run `/sk:continue <change-id>` for the spec delta. Do not run it yourself.

## Guardrails

- Writes `proposal.md` only. No project code is edited, no spec delta, design or tasks are written, and neither `/sk:continue` nor `/sk:apply` is invoked from within this command, whatever the request said or however it justified going further
- Never create `sk/` as a side effect
- Never fabricate work item content, and never proceed from an empty AC field as if it were filled — Branch B asks instead
- Ambiguity that changes scope, observable behaviour, compatibility, or which capability owns the work goes to the user, via Branch B or a Gap
- Decide small conventions yourself and record the assumption
- Read dependency artifacts from disk each time, not from memory of this conversation
- Azure DevOps is read-only here: no comments, no new work items, no state changes — even if asked
