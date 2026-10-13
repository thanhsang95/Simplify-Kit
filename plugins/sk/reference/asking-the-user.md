# Asking the user

How SimplifyKit puts a round of questions to a person. Read by `/sk:propose` (Step 4), `/sk:archive` (ADR and glossary drafts) and `/sk:init` (migration items).

Each skill decides **what** to ask and **when** a round is over. This file only decides **how** the round reaches the person.

## Use `AskUserQuestion` when you can

When the `AskUserQuestion` tool is available **and** the request did not say nobody can answer, put every question that has discrete answers through it:

- One question per decision. Keep the skill's id at the start of the question text (`G1 — …` for `/sk:propose`), because the id is what `## Assumptions` and later rounds refer back to
- Your recommended answer is the **first** option, with `(Recommended)` at the end of its label. The other options are the real alternatives, not filler. Editing or answering something else goes through the free-text "Other" the tool always adds, so do not spend an option on it
- The tool takes at most 4 questions per call. A round with more than 4 is still **one round**: make the calls one after another, and do not start the next round's questions until every call in this one is answered

Without the tool, a person has to type back "G1 ok, G2 the second one, …" against a wall of text. With it they pick, and only type when they disagree.

## Show first, then ask

Anything the person has to read before deciding — the draft ADR, each draft glossary term, the exact text a migration would append and to which file, how the acceptance criteria were split — goes into your response as text **before** the tool call. The tool's options hold a label and a line of description, not a draft; a question about content the person cannot see gets answered blind.

## When to stay in text

- **Open questions** — ones whose answer is content, not a choice: "what are the acceptance criteria?", "what should this term mean instead?". Ask them in text, in the skill's own format, in the same round
- **No tool.** Headless runs (`claude -p`), the eval runner, and any session without `AskUserQuestion` get the skill's text format unchanged. It is the fallback, not a legacy path — keep it working
- **Nobody can answer.** When the request says so, do not call the tool. The skill's unattended rule applies exactly as written: the questions still appear in your response as text, and what happens to their answers (`unconfirmed`, skipped, printed) is that skill's decision

This is a preference, not a requirement, because the tool cannot carry every question this kit asks and is not present in every run. A rule that made it mandatory would stall the runs that have no tool and turn open questions into fake multiple choice.
