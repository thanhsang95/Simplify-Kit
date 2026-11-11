---
name: verify
description: "SimplifyKit (sk): check that the implementation of a change under sk/changes/ matches its spec delta, tasks and design, review the code itself for bugs the spec never mentions, and report what is missing before archiving — read-only, it fixes nothing. Also reviews a teammate's Azure DevOps pull request with `/sk:verify --pr <id>`. Use when the user says \"sk verify\", \"verify the change\", \"is us-12345-... ready to archive\", or a change's tasks look done and should be checked against what it promised before /sk:archive."
metadata:
  author: Simplify
  version: "0.5.0"
---

Check one change's implementation against its planning artifacts, review the code's health, and report the gaps. **This command only reads.** It is a review the next step can act on, not a fix.

Adapted from OpenSpec's `openspec-verify-change` (three dimensions, three severities, graceful degradation) with two ideas from `mattpocock/skills`' `code-review`: review the diff since a fixed point rather than keyword-searching the whole codebase, and report behaviour nobody asked for. Both are MIT.

## Step 1 — Select the change

`--pr <id>` in the request → Step 1a decides. Otherwise, as `/sk:apply`: the id in the request → the one under discussion → the only open change → otherwise list and ask. Exclude `archive/` when listing. An id with no open change but a `sk/changes/archive/<id>/` → verify that copy, as `/sk:pr` does: authors archive before publishing and still run fix rounds after. Announce `Verifying change: <id>` (add `(archived)` when it is) and how to override it (`/sk:verify <other-id>`).

**No change.** The request says no change covers the code, names code no open change's tasks point at, or there is no open change → no-change mode: only Step 7 (on the paths named, or the diff) and Step 8 run; Completeness, Correctness and Coherence go under **Skipped** because there is no change. With a person and no `--pr`, ask once: "No sk change covers this — run only code health and tests?" With `--pr`, or nobody can answer, run it and say so.

## Step 1a — `--pr <id> [<worktree-path>]`

Reviewing a teammate's pull request: follow `${CLAUDE_PLUGIN_ROOT}/reference/pr-review.md` — REST only, no git command that writes (without a path, print the fetch and worktree commands and stop), the standard taken from `sk/specs/` when the change was archived, `sk/config.yaml` from the target branch.

## Step 2 — Load the change from disk

Read from disk, even if seen earlier:

- `sk/changes/<id>/proposal.md`, `specs/**/spec.md`, `design.md` if present, `tasks.md`
- `sk/config.yaml` — its `rules`, and the docs its `context` points at, are the standards for Coherence and Code health; `sensitive:` lists the risky paths
- `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` — it defines the open-question marker
- **The previous round's report**, if there is one: pasted by the user, an earlier verification report for the same change in this conversation, or the PR thread (Step 1a). It is input, never a file to read from or write to. None → this is round 1

No `tasks.md` in an open change → nothing is built yet; point at `/sk:continue <id>` or `/sk:apply <id>` and stop.

## Step 3 — Pin what changed

When a shell is available, take the fixed point the user named, else the merge-base with the main branch (`git merge-base HEAD <main>`). Collect `git diff <base>...HEAD` plus uncommitted changes (`git diff HEAD`), and the commit list. Confirm the base resolves and the diff is non-empty before going on — an empty diff with ticked tasks is itself a CRITICAL finding.

**Round 3 on**, look for new findings only in the diff since the previous report's Head (`git diff <Head>...HEAD`, plus uncommitted): Completeness still counts everything, but a finding still open from the previous report gets a status line, not a fresh review. Head `not available` → review the whole diff and say so. Repeated full reviews keep surfacing new nits, so the rounds never end.

**No shell:** read the code the tasks and the delta point at (Grep/Read). Say in the report that the diff was not available, so the scope check in Step 5 was skipped.

## Step 4 — Completeness

- **Tasks.** Parse the checkboxes in `tasks.md`: a box holding only `x`/`X`, ignoring spacing (`- [ x]`), is done; every other marker (`- [ ]`, `- []`, `- [~]`, `- [-]`) is not. Each open task → CRITICAL
- **Requirements.** For every `### Requirement:` in the delta, find implementation evidence (file and lines). None found → CRITICAL, **even when every task is ticked** — a ticked box is a claim, and this is where the claim gets checked

## Step 5 — Correctness

- **Scenarios.** For every `#### Scenario:`, check that the code handles its `WHEN` and produces its `THEN`, and whether a test covers it. Code that looks like it diverges from the scenario → WARNING. No test → WARNING
- **Open questions.** A scenario still carrying the open-question marker → CRITICAL: `/sk:archive` stops on it (its check 2). Name the `Q<n>` from `proposal.md`. List every task ticked `(built on Q<n>)` alongside, so whoever answers the question sees what assumed the current reading
- **Scope.** Behaviour in the diff no requirement or task asks for → WARNING; if listed under `## Out of scope`, name the entry and its source — the code went against a decision. Tests, named refactors and needed wiring are not extra scope

Quote the spec line for each finding.

## Step 6 — Coherence

- **Contracts.** Compare each `## Contracts` interface with the code: name, parameters, types, shape, errors (not the body). Missing or different → CRITICAL — a person reviewed it and callers were built against it. Recommend a code change or a `design.md` update the person agrees to; never pick silently
- **Design.** If `design.md` exists, check the implementation follows each decision it records. Contradiction → WARNING, recommending either a code change or a `design.md` update. No `design.md` → say so and skip
- **Standards.** Check the diff against `sk/config.yaml` → `rules` and the docs `context` points at. A documented rule broken → WARNING. A deviation from the surrounding code's patterns → SUGGESTION. The repo's documented standards win over your taste; skip anything a linter or type checker already enforces

## Step 7 — Code health

The steps above check what the change promised; this one checks the code for defects nobody wrote a scenario about.

- **Who.** With the Agent tool, run this step in a subagent with a fresh context that receives only the diff, the standards docs `context` names and `sensitive:` — never the proposal, spec, design or tasks, so it reads what the code does rather than what it was meant to do. No Agent tool → do it here and list that under **Skipped**. No diff → read the files the tasks and delta point at, or the paths the user named, and say the scope was narrowed
- **Look for** logic errors, swallowed errors, null and boundary values, concurrency, credentials or sensitive data reaching logs, missing authorization. Skip what a linter or type checker catches
- **Evidence.** Every finding names `file:line` and what the code there does, read from the code — never guessed from a name. The same defect in several places → one finding listing every location
- **Severity.** CRITICAL only with concrete evidence: a security hole, data loss, or a crash with the path that reaches it. Otherwise WARNING or SUGGESTION, lower when unsure. Outside the diff → `pre-existing`, at most SUGGESTION, never a reason not to archive. Without a diff, all code read counts as in scope
- Nothing found → say so. Never pad the section

## Step 8 — Run the tests

When a shell is available and `sk/config.yaml` records a test command (in `--pr` mode, the target branch's — Step 1a), run it. Failures → CRITICAL, with the failing test names. Otherwise say the tests were not run and why.

## Step 9 — Report

```markdown
## Verification report: <change-id | no change — <paths or PR id>>

Round: <n> · Base: <short sha | not available> · Head: <short sha | not available>

| Dimension    | Status                                 |
|--------------|----------------------------------------|
| Completeness | X/Y tasks, N/M requirements implemented |
| Correctness  | K/L scenarios covered, tests: pass/fail/not run |
| Coherence    | followed / N issues / no design.md     |
| Code health  | clean / N findings / not run           |

### CRITICAL — fix before /sk:archive
- **V1** — <finding> (`file:line`) — <recommendation>
### WARNING — should fix
### SUGGESTION — nice to fix

### Code health
- **V2** — WARNING — <finding> (`file:line`, `file:line`) — <recommendation>

### Still open from round <n-1>
- **V<n>** — <severity>, still open
### Resolved since round <n-1>
- **V<n>** — <the previous round's one-line finding>

### Disposition

| ID | Severity | Disposition |
|----|----------|-------------|
| V1 | CRITICAL |             |

### Skipped
```

Every finding carries a `file:line` reference where one exists and one specific recommendation — never "consider reviewing". The severity sections hold findings against the artifacts; `### Code health` holds Step 7's, each with its severity. List under **Skipped** each check that did not run and why (no shell, no `design.md`, no test command, no change, code health inline). Base and Head are the commits Step 3 compared — the next round needs them; without a shell, `not available`. **Still open** is used from round 3 (Step 3); before that, open findings are restated in full.

**Finding IDs.** Every finding gets an ID `V<n>`, numbered across the whole report, Code health included, not per severity. With a previous report:

- A finding still present keeps its ID, even if its severity changed. Match on the file, the requirement or scenario it concerns, and the kind of problem — not on wording
- A new finding takes the next number after the highest ID the previous report used; never reuse a number
- A previous ID no longer found goes under **Resolved since round <n-1>** — never dropped silently. Round 1 → leave the section out
- Unsure whether a finding is an old one → give it a new ID and write `possibly V<n>` after it

**Disposition** is the author's column: `fixed`, `wrong`, `intended` or `wontfix`. Leave it blank for new findings; for a finding that keeps its ID, carry over what the previous report held. Never fill it in yourself, and never change a severity or the closing line because of it — the person weighs it.

Print the report as one contiguous markdown block, heading to closing lines, so it pastes as one PR comment that shows the full current state.

End with one closing line, counting Code health findings too (no-change mode: `merge` in place of `/sk:archive`):

- CRITICAL present → `N critical issue(s). Fix before /sk:archive.`
- Warnings only → `No critical issues, N warning(s). Ready for /sk:archive once you have weighed them.`
- Nothing → `All checks passed. Ready for /sk:archive.`

Then, each only when it applies:

- The diff touches a `sensitive:` glob → `Touches <glob>: consider running /security-review.` Never run it yourself
- Round 4 or later → `Round <n>: consider stepping back to rethink the approach rather than another fix round.`
- `--pr` with a path → `When done: git worktree remove <path>`

**When unsure, rank lower**: SUGGESTION over WARNING, WARNING over CRITICAL. CRITICAL means the change does not do what it promised, or Step 7 has concrete evidence of harm — reserve it for that.

## Guardrails

- Read-only. Never edit project code or any artifact under `sk/`, never tick or untick a task, never create a file — the report, rounds included, lives only in the reply
- No git command that writes: no `fetch`, `worktree add` or `remove`, `checkout`, `stash` — print them for the person
- Never invoke `/sk:apply`, `/sk:archive` or `/security-review` — report, and let the user decide what is next
- Not a gate, and not a copy of `/sk:archive`'s merge checks (scenario count, conflicts)
- Judge against the artifacts on disk, not against your own idea of what the feature should do
- Azure DevOps: reads only the PR and its threads over REST, only with `--pr`; never writes — no comment, vote, thread status or state. Posting the report is the person's step. Without `--pr` there is no Azure DevOps access: the delta was built from the work item by `/sk:continue`; this compares code with the delta
