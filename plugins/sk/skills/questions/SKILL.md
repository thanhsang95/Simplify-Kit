---
name: questions
description: "SimplifyKit (sk): write the open questions of a change under sk/changes/ — its Gaps, open questions and unconfirmed assumptions — into one questions file a PO or BA can answer, with context, options and a suggested answer for each. Use when the user says \"sk questions\", \"questions for the PO on us-12345-...\", or wants what a change is still waiting on sent to the product owner or analyst. Writes sk/changes/<id>/questions.md only."
metadata:
  author: Simplify
  version: "0.1.0"
---

Turn what one change is still waiting on into a file a product owner or business analyst can read and answer without knowing `sk`. Before this, `/sk:continue` printed a numbered list to paste into a work item comment, and Gaps and unconfirmed assumptions never left `proposal.md` at all.

## The file is a copy, never the source

`proposal.md` holds the questions; this file is a view of them, rewritten from scratch on every run. **Answers never come back through this file.** They come back as a comment on the work item — `/sk:propose <id>` re-run reads comments and a comment wins — or in a conversation with whoever runs `sk`, where `/sk:continue` records them with their source. A second place to write answers would be a second place for them to drift.

Writes nothing else: no `proposal.md` edit, no comment, nothing on Azure DevOps (read-only throughout the kit).

## Step 1 — Select the change

The id given in the request → the change discussed earlier in this conversation → the only open change → otherwise list and ask. Exclude `archive/`: a merged change has nothing left to ask. Announce `Using change: <id>`.

## Step 2 — Collect, from disk

Read `proposal.md`, the spec delta (if any) and `tasks.md` (if any). Collect, in this order:

1. **Gaps** — criteria that could not become behaviour, missing criteria (`AC source: none yet`), pending confirmations of a related item, parent or test case
2. **Open questions** — each `Q<n>` under `## Open questions`, and the scenario carrying its `[[OPEN:Q<n>]]` marker
3. **Unconfirmed assumptions** — each `## Assumptions` entry marked `unconfirmed`: a reading nobody has checked, which the build already leans on

For each, note which tasks are ticked `(built on Q<n>)` — that is what changes if the answer differs from the reading used.

**Nothing to ask** — all three empty: write no file, say so. When an older `questions.md` is there, say it is out of date and can be deleted; do not delete it.

## Step 3 — Write `sk/changes/<id>/questions.md`

Overwrite it if it exists. In the language `proposal.md` is written in. The reader is not a developer: no `[[OPEN:…]]` marker, no `SHALL`, no file paths, no "scenario", "delta" or "token" — say "the rule", "the screen", "the criterion".

```markdown
# Questions on AB#<id> — <work item title>

<One line: what the change is, from proposal.md's Summary.>
Please answer as a comment on AB#<id>, quoting each question's number.
<For a req- change: "Please answer <whoever asked> directly, quoting each number.">

_Written from proposal.md on <date>. That file is the source; this one is rewritten when it changes._

## 1. <short title>

**Where it comes from:** <the criterion or comment, quoted, and what it leaves undecided>
**Question:** <one question, answerable in a sentence>
**Options:** <two to four concrete options, when the answer is a choice>
**Suggested:** <your recommended answer and why, in one line>
**Already built on:** <the reading used so far, when tasks lean on it; omit otherwise>

<!-- ref: Q<n> | Gap | Assumption -->
```

- One question per number. Gaps first, then open questions, then unconfirmed assumptions — what blocks the spec before what blocks archiving, before what only needs a check
- Quote the source text; never restate it so it reads more decided than it is
- A suggestion is a suggestion: never state it as the answer, and never write a value no source and no reasoning supports. When you cannot suggest one, say why
- The `ref` comment is the only `sk` term in the file; it lets whoever records the answer find the matching entry in `proposal.md`

## Step 4 — Close out

Name the file, how many questions it holds by kind, and how answers come back (a comment on the work item, then `/sk:propose <id>` to re-run, or `/sk:continue <id>` when the answer is given in conversation). Nothing else.

## Guardrails

- Writes `sk/changes/<id>/questions.md` and nothing else; edits no artifact, never touches Azure DevOps
- Every question traces to a Gap, an open question or an `unconfirmed` assumption in `proposal.md`; no new questions of your own
- Answers are never read from this file
- Nothing to ask → no file
