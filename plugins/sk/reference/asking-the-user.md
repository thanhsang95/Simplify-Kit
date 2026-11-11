# Asking the user

How a round of questions reaches a person. Read by `/sk:propose` (Step 4), `/sk:archive` (ADR and glossary drafts) and `/sk:init` (migration items). Each skill decides **what** to ask and when a round ends; this file decides only **how**.

## Use `AskUserQuestion` when you can

When the tool is available **and** the request did not say nobody can answer, put every question with discrete answers through it:

- One question per decision, the skill's id first in the text (`G1 — …`) — `## Assumptions` and later rounds refer back to it
- Your recommended answer is the **first** option, labelled `(Recommended)`. The others are real alternatives; editing goes through the tool's built-in "Other"
- At most 4 questions per call. A bigger round is still **one round**: make the calls back to back, and start no next-round question until all are answered

## Show first, then ask

Anything the person must read to decide — a draft ADR, glossary terms, the exact text a migration appends and where, how the criteria were split — goes in your response as text **before** the tool call. An option holds a label, not a draft.

## When to stay in text

- **Open questions** whose answer is content ("what are the acceptance criteria?") — in text, in the skill's format, same round
- **No tool** (`claude -p`, the eval runner) — the skill's text format, unchanged. It is the fallback, not a legacy path
- **Nobody can answer** — do not call the tool; the questions still appear as text, and the skill's unattended rule decides what happens to them

A preference, not a requirement: the tool is not in every run and cannot carry open questions.
