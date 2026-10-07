---
name: verify
description: "SimplifyKit (sk): check that the implementation of a change under sk/changes/ matches its spec delta, tasks and design, and report what is missing before archiving — read-only, it fixes nothing. Use when the user says \"sk verify\", \"verify the change\", \"is us-12345-... ready to archive\", or a change's tasks look done and should be checked against what it promised before /sk:archive."
metadata:
  author: Simplify
  version: "0.1.0"
---

Check one change's implementation against its planning artifacts and report the gaps. **This command only reads.** It is a review the next step can act on, not a fix.

Adapted from OpenSpec's `openspec-verify-change` (three dimensions, three severities, graceful degradation) with two ideas from `mattpocock/skills`' `code-review`: review the diff since a fixed point rather than keyword-searching the whole codebase, and report behaviour nobody asked for. Both are MIT.

## Step 1 — Select the change

Same as `/sk:apply`: the id in the request → the one under discussion → the only open change → otherwise list and ask. Exclude `archive/` when listing. Announce `Verifying change: <id>` and how to override it (`/sk:verify <other-id>`).

## Step 2 — Load the change from disk

Read, from disk, even if you saw them earlier in this conversation:

- `sk/changes/<id>/proposal.md`, `specs/**/spec.md`, `design.md` if present, `tasks.md`
- `sk/config.yaml` — its `rules`, and the docs its `context` points at, are the standards for Coherence
- `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` — it defines the open-question marker

No `tasks.md` → nothing is built yet; point at `/sk:continue <id>` or `/sk:apply <id>` and stop.

## Step 3 — Pin what changed

When a shell is available, take the fixed point the user named, else the merge-base with the main branch (`git merge-base HEAD <main>`). Collect `git diff <base>...HEAD` plus uncommitted changes (`git diff HEAD`), and the commit list. Confirm the base resolves and the diff is non-empty before going on — an empty diff with ticked tasks is itself a CRITICAL finding.

**No shell:** read the code the tasks and the delta point at (Grep/Read). Say in the report that the diff was not available, so the scope check in Step 5 was skipped.

## Step 4 — Completeness

- **Tasks.** Parse the checkboxes in `tasks.md`: a box holding only `x`/`X`, ignoring spacing (`- [ x]`), is done; every other marker (`- [ ]`, `- []`, `- [~]`, `- [-]`) is not. Each open task → CRITICAL
- **Requirements.** For every `### Requirement:` in the delta, find implementation evidence (file and lines). None found → CRITICAL, **even when every task is ticked** — a ticked box is a claim, and this is where the claim gets checked

## Step 5 — Correctness

- **Scenarios.** For every `#### Scenario:`, check that the code handles its `WHEN` and produces its `THEN`, and whether a test covers it. Code that looks like it diverges from the scenario → WARNING. No test → WARNING
- **Open questions.** A scenario still carrying the open-question marker → CRITICAL: `/sk:archive` stops on it (its check 2). Name the `Q<n>` from `proposal.md`. List every task ticked `(built on Q<n>)` alongside, so whoever answers the question sees what assumed the current reading
- **Scope.** Behaviour in the diff that no requirement and no task asks for → WARNING. `/sk:apply` must surface extra scope, never absorb it; this is where absorbed scope shows up. Tests, refactors a task names, and wiring a requirement needs are not extra scope

Quote the spec line for each finding.

## Step 6 — Coherence

- **Design.** If `design.md` exists, check the implementation follows each decision it records. Contradiction → WARNING, recommending either a code change or a `design.md` update. No `design.md` → say so and skip
- **Standards.** Check the diff against `sk/config.yaml` → `rules` and the docs `context` points at. A documented rule broken → WARNING. A deviation from the surrounding code's patterns → SUGGESTION. The repo's documented standards win over your taste; skip anything a linter or type checker already enforces

## Step 7 — Run the tests

When a shell is available and `sk/config.yaml` records a test command, run it. Failures → CRITICAL, with the failing test names. Otherwise say the tests were not run and why.

## Step 8 — Report

```markdown
## Verification report: <change-id>

| Dimension    | Status                                 |
|--------------|----------------------------------------|
| Completeness | X/Y tasks, N/M requirements implemented |
| Correctness  | K/L scenarios covered, tests: pass/fail/not run |
| Coherence    | followed / N issues / no design.md     |

### CRITICAL — fix before /sk:archive
### WARNING — should fix
### SUGGESTION — nice to fix

### Skipped
```

Every finding carries a `file:line` reference where one exists and one specific recommendation — never "consider reviewing". List under **Skipped** each check that did not run and why (no shell, no `design.md`, no test command).

End with one line:

- CRITICAL present → `N critical issue(s). Fix before /sk:archive.`
- Warnings only → `No critical issues, N warning(s). Ready for /sk:archive once you have weighed them.`
- Nothing → `All checks passed. Ready for /sk:archive.`

**When unsure, rank lower**: SUGGESTION over WARNING, WARNING over CRITICAL. CRITICAL means the change does not do what it promised — reserve it for that.

## Guardrails

- Read-only. Never edit project code or any artifact under `sk/`, never tick or untick a task, never create a file
- Never invoke `/sk:apply` or `/sk:archive` — report, and let the user decide what is next
- Not a gate: `/sk:archive` does not require this to have run, and runs its own merge checks. Do not repeat them here — the scenario-count and conflict checks live in `/sk:archive` only
- Judge against the artifacts on disk, not against your own idea of what the feature should do
- No Azure DevOps access at all — the delta was built from the work item by `/sk:continue`; this compares code with the delta
