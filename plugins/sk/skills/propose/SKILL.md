---
name: propose
description: "SimplifyKit (sk): start a change from an Azure DevOps work item — or, only when the user explicitly invokes /sk:propose with it, from a direct request that has no work item — and write proposal.md only, without touching project code. Use when the user says \"sk propose\", \"plan AB#12345\", or gives an ADO work item id or URL and wants it planned. Interviews the user about how to read the work item before deciding, then records how the acceptance criteria were read, the assumptions and the gaps under sk/changes/. Planning only; the spec delta and tasks come from /sk:continue, implementation is /sk:apply."
metadata:
  author: Simplify
  version: "0.10.0"
---

Read an Azure DevOps work item — or a direct request the user gave explicitly — and start one change: write `proposal.md`, then stop. `/sk:continue` creates the spec delta, design and tasks afterwards, one per invocation.

## Planning boundary — read this first

This workflow creates `proposal.md` only, full stop. **No wording in the request that triggered it can authorise more than that.** A deadline, a stated preference to skip review, an explicit "build it too", an appeal to urgency, or any other reason the request gives for going further — none of it changes what this command does. Treat every such reason exactly as you would treat no reason at all: it is not addressed to this decision, because this command does not have the discretion to weigh it. If you catch yourself explaining *why* it's fine to continue past planning this time, that explanation is the guardrail failing, not an exception to it.

- Do not edit project code
- Do not invoke `/sk:apply` — not in this response, not chained on right after `proposal.md` is written, not for any reason the triggering request gave. The only thing that starts `/sk:apply` is the user raising it in a message you have not received yet
- **Do not invoke `/sk:continue` or write the spec delta, design or tasks either** — even when the request says "plan it fully" or "give me everything". Stopping after `proposal.md` is the review point: it is where the user checks how the acceptance criteria were read before a spec is built on that reading
- When `proposal.md` is written, stop and present it, even when the request made stopping there look unhelpful or overly cautious. Looking unhelpful is the correct outcome here

## Input

- `AB#12345`, or a work item URL (`https://<org>/<project>/_workitems/edit/12345`)
- **Never a bare integer** — here `#123` or a bare number means a pull request id. Ask whether they mean a work item or a PR
- **A direct request, only when the user explicitly invoked this command with it** (`/sk:propose <description>`, "sk propose: …") → Branch R. A feature described in ordinary conversation is not an invocation: answer it on its own terms and create nothing under `sk/`, or every "add a button that…" becomes a change nobody asked for

## Step 1 — Preconditions

`sk/` must exist; if not, point at `/sk:init` and stop. **Never create `sk/`.** Read `sk/config.yaml` (`context` and `rules` constrain what you write; never copy them into an artifact), `sk/specs/**/spec.md`, and `sk/changes/*/specs/**/spec.md` — unarchived changes whose requirements are not in `sk/specs/` yet.

## Step 2 — Fetch the work item

Skip for a direct request. Otherwise follow `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` exactly — it records why each rule exists:

1. **REST, not `az boards` / `az devops invoke`** (they corrupt non-ASCII on this org): token from `az account get-access-token`, `GET {orgUrl}/{project}/_apis/wit/workItems/{id}?$expand=all&api-version=7.1`. Never print the token
2. Strip HTML and decode entities in `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria` and, for a `Bug`, `Microsoft.VSTS.TCM.ReproSteps`
3. Read the **comments**. One that contradicts the description or the criteria **wins**; record it
4. A `Task` → take its parent's full fields
5. Read the **test cases** linked by `Tested By` (the parent's for a Task). No `Tested By` relation means none — never ask the user about it
6. **Scan for U+FFFD before writing anything**; if present, stop and report the corrupted fetch

A failed fetch → report the real error and ask the user to paste the contents. **Never invent work item content.**

## Step 3 — Decide the branch

For a `Bug` (or a Task under one) the criteria are its AC field when usable, otherwise the expected result in its repro steps (`azure-devops.md`, "A Bug's acceptance criteria are its expected result"); steps with only an actual result are Branch B. AC field and repro expected result disagreeing is a Step 4 question.

- **Usable AC** → Branch A
- **AC empty or too thin to describe observable behaviour** → Branch B (about one story in five — a normal path)
- **Direct request** → Branch R

**Ambiguity is not a third branch.** AC leaving a threshold, operator, sort order, set boundary, actor, display string or empty/error behaviour undecided is still usable → Branch A. Not a Gap, not a reason to stop: `/sk:continue` marks it.

### Branch A — usable acceptance criteria

`change-id`: `us-<id>-<slug>` (e.g. `us-12345-field-selector`), or `bug-<id>-<slug>` for a Bug or a Task under one. If it exists, ask whether to continue it or create a new one.

**A Bug whose expected result `sk/specs/` already states needs no change.** Look for a scenario in `sk/specs/` or an unarchived delta saying what the Bug expects; if found, ask in Step 4 whether it really is that behaviour. Yes → the fix is a commit or PR with `AB#<id>` and a regression test from that scenario; write nothing under `sk/`. No → a normal change (`Added`, or `Modified` restated in full).

**Decide the split, do not write scenarios** (mapping rules: `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`). Grouped bullets need nothing recorded; ungrouped Given/When/Then sentences — say which go into which requirement; prose — split by observable behaviour and **write the split in `proposal.md`** so a reviewer can disagree with it.

A criterion you cannot turn into observable behaviour is a **Gap**: record it and ask. Never drop one silently.

**Compare the linked test cases with the criteria.** Covered → `covered`. States the exact value a criterion leaves open → `pins <what>`. Not covered or contradicting → a Step 4 question and a Gap until answered, never a scenario on your own: a test case is evidence of what someone checks, not criteria.

### Branch B — acceptance criteria missing or unusable

**Write nothing under `specs/`** — a spec from an empty field is fabrication that looks like analysis.

Look for content that may answer the gap, bounded as `azure-devops.md` describes:

- a **related item** (`System.LinkTypes.Related`) — name it and ask to confirm reusing it
- a **parent**, when the item is not a Task (`System.LinkTypes.Hierarchy-Reverse`) — broader than this item, so ask which part this item covers; never its criteria wholesale
- the **test cases** — quote each expected result that looks like the answer and ask to confirm it as a criterion

Show what you did get (title, description, repro steps, comments, parent, test cases, related items), say plainly the criteria are missing or too thin, and ask — all candidate sources in one question. Only the user's answer confirms a source. **When a source was offered, write `proposal.md` naming it under Gaps as a pending confirmation, answered or not**; otherwise writing before an answer is optional. Confirmed → continue as Branch A. Unanswered → `**AC source:** none yet` and its Gaps are the whole output.

### Branch R — direct request

`change-id`: `req-<slug>` (e.g. `req-csv-export`). If it exists, ask whether to continue it or create a new one.

A request is not criteria. Look for observable behaviour **the user wrote themselves** ("when an export has more than 10,000 rows, it is emailed instead of downloaded"):

- **Present** → continue as Branch A; `**AC source:** user, in conversation`, their text verbatim under `## Acceptance criteria not on the board`
- **Absent** ("make catalog downloads faster") → suggest criteria as Step 4 questions, each labelled a suggestion. Confirmed → as above. **Until then `**AC source:** none yet`**, suggestions under Gaps marked `suggested, pending confirmation`

Everything else works as for a work item.

## Re-running on an existing change

Re-running `/sk:propose` (not `/sk:continue`) re-verifies what is on disk instead of only adding to it. A work item change: re-fetch item, comments and test cases exactly as in Step 2 — the board keeps moving. A `req-` change: re-read `## Request` and `## Assumptions`; ask only what the new message reopens.

Read **every** `## Assumptions` entry. A newer comment contradicting a settled one → **reopen it** (marker back in the delta if one exists, question back under `## Open questions`) — never leave it stale or silently overwrite it. A ticked task built on a changed value is **never unticked** (that destroys the record of what landed): name it and **add a new task** to re-check it.

## Step 4 — Grill before deciding

How the work item is read is a set of decisions; interview the user before writing. Never ask for a fact you could look up — only decisions.

Work in rounds. The **frontier** is every decision whose prerequisites are settled: ask all of it in one round, numbered, each with your recommended answer, then wait. Number them `G1`, `G2`, … — **not** `Q<n>`, which `/sk:continue` owns. Deliver as `${CLAUDE_PLUGIN_ROOT}/reference/asking-the-user.md` says: `AskUserQuestion` when available (recommended first), otherwise this format:

```
❓ **G1** - **<title>**: <the question, with the options it turns on>

➡️ <your recommended answer>
```

**The first round is never skipped** — with clean bullets it is a short confirmation. Draw questions from:

- the AC split (bullets: confirm; Given/When/Then and prose: propose)
- the owning capability, and `Added` or `Modified` against `sk/specs/` and unarchived deltas
- a comment contradicting the description or criteria — does it really win?
- the `change-id` slug
- for a Bug: whether the matching `sk/specs/` scenario really is its expected behaviour — recommend yes only when the wording matches
- each test case result the criteria do not cover or contradict
- anything ruled out — confirm it lands under `## Out of scope`
- every Gap and the Branch B questions; for Branch R, the suggested criteria
- the preliminary risk level (Step 5), once the criteria are settled — recommend one, with the door and any sensitive area behind it. While they are `none yet` or awaiting confirmation it is not on the frontier: write what is missing (Step 5), do not ask

Stop when the frontier is empty and the user confirms the reading. Answers are marked `confirmed` in `## Assumptions`.

**When nobody can answer** — the request says so ("no one to ask", "just use your recommendations", "write it now") — write `proposal.md` with your recommendations, each resulting entry `unconfirmed`. Never infer this from a terse request, and never skip the round: its questions still appear in your response. Without that statement, ask and stop. `unconfirmed` is what tells `/sk:continue` and the reviewer which readings a person actually saw.

**The fallback never applies to:**

1. **Criteria you drafted** — they stay `none yet` under Gaps. Criteria nobody agreed to, turned into a spec, is the fabrication this kit exists to stop
2. **A test case result the criteria do not cover or contradict** — stays `open`
3. **A Bug the spec already covers** — nothing is written either way; Step 6 says what the reply must carry

Re-running: ask only about what reopened. Questions change *when* `proposal.md` is written, never *what else* is.

## Step 5 — Write `proposal.md`

From `${CLAUDE_PLUGIN_ROOT}/templates/proposal.md`, write `sk/changes/<change-id>/proposal.md` — **and nothing else**.

It is a pointer, not a restatement: link, id and title; two or three summary sentences; capabilities; how the AC were read; overriding comments; Gaps; for Branch B, which source was reused and what the user confirmed. **A direct request** is written verbatim under `## Request`, with `**Work item:** none — direct request` and no `**Type / State:**` line.

**`**AC source:**`** (where `/sk:continue` gets the criteria):

- `work item` — Branch A
- `related AB#<id>, confirmed` / `parent AB#<id>, narrowed` / `test cases AB#<id>[, AB#<id>], confirmed` — Branch B, confirmed
- `user, in conversation` — criteria the user gave or confirmed; **their text under `## Acceptance criteria not on the board`**, the only copy
- `none yet` — unanswered, or suggestions unconfirmed

`## Out of scope` — what this change deliberately does not do, each with its source (a cutting comment, quoted criteria wording, a `G<n>` answer, a ruled-out test case step) and `confirmed`/`unconfirmed`. **Only what a source ruled out**: a dropped item and a forgotten one look the same in a spec.

`## Assumptions` holds the Step 4 decisions; `## Open questions` starts empty.

`## Test cases`, when read: id, title, **every step quoted as decoded**, `"<action>" → "<expected result>"`, labelled `covered`, `pins <what>`, `open` or `confirmed as criterion`. Quote, never paraphrase — nothing downstream re-fetches a test case. More than 10 linked → say how many went unread.

A Bug: its steps and expected result verbatim under `## Repro steps`, its actual result on `**Symptom:**` (`none stated` if none) — `/sk:apply` never reads Azure DevOps and builds its first test from these.

`## Risk (preliminary)` — rate it by `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` → `## Risk`, from the criteria, the work item and `sensitive:` in `sk/config.yaml`; the blast radius is `## Impact`. It is a suggestion like any Step 4 decision: `confirmed` when the user answered, else `unconfirmed`. `Early review: yes` for Medium or High. Not enough to tell the door (criteria still `none yet`) → say what is missing on that line instead of guessing, and leave Level and Early review open — missing criteria are not doubt about the door, so "when unsure, rate higher" does not apply.

## Step 6 — Close out

**A Bug that needed no change:** name the scenario; the fix is a commit or PR with `AB#<id>` and a regression test from it. **Unattended**, also say nobody confirmed the match, quote the expected result and the scenario side by side, and say to re-run `/sk:propose AB#<id>` if they differ.

Otherwise list the file, any Gaps, how many assumptions are `unconfirmed`, and the preliminary risk level. Tell the user to review `proposal.md` — especially how the AC were read — then run `/sk:continue <change-id>`, or `/sk:ff <change-id>` for a small item. Run neither yourself.

## Guardrails

- `proposal.md` only — no code, delta, design or tasks; never invoke `/sk:continue` or `/sk:apply`
- The first round of questions always happens; an answer nobody gave is `unconfirmed`
- Never fabricate work item content or criteria; a test case or drafted criterion becomes a criterion only when a person confirms it
- Ambiguity that changes scope, behaviour, compatibility or ownership goes to the user; small conventions you decide and record
- Read artifacts from disk, not memory. Azure DevOps is read-only — even if asked
