# Changelog

## 0.8.0 — 2026-10-27

`/sk:apply` works test-first: each `#### Scenario` in the spec delta gets a test written from that scenario before its code, seen failing for the right reason, then seen passing. Before this, nothing tied the code to the scenarios except a ticked box, and the close-out only suggested running the tests. The rules are in the new `reference/tdd.md`, adapted from `mattpocock/skills`' `tdd` (MIT): red before green, one slice at a time, test at the public seam, expected values from the scenario rather than computed the way the code computes them.

- **The seam is the scenario, not asked again.** The source skill confirms each seam with the user before any test. Here the spec review already did that, and asking would block every unattended run
- **No shell, no claim.** Without Bash (eval runs, restricted sessions) the test is still written but not run, and the close-out says so. "Saw it fail" or "it passes" about a run that did not happen is forbidden, the same rule `/sk:verify` Step 7 keeps
- **No test setup, no install.** With no `Test:` line (or the template's `<command>`) and no tests in the repo, `apply` never installs a framework or invents a command. It asks once in Step 3 with a person present, and skips test-first with the reason when nobody can answer
- **Exceptions are written down:** tasks that change no behaviour, scenarios that cannot be tested automatically (named in the close-out, never a fake test), `REMOVED` (delete the tests with the code), `MODIFIED` (new tests only for changed scenarios, rerun the rest), a test that passes before the code, a test that will not pass (a blocker, never loosened), a scenario spread over several tasks (red until its last task)
- **Contracts are reviewed at design time.** Test-first made a gap visible: `/sk:apply` chose the code-level interface (signature, endpoint, props) itself, after the last human review, then wrote every test against it — a wrong interface came out consistently wrong in code and tests, and `/sk:verify` compares against the spec, which is in product terms, so nothing caught it. `design.md` is now written when the change adds or changes a public interface, with each one under a new `## Contracts` section in the repo's own language, naming the scenarios it serves. `Skipped` is only for a change with no interface change and no trade-off. `continue`'s tasks build the contracts as written; `apply` tests through them and stops to ask rather than ship a different signature; `verify` reports a missing or different contract as CRITICAL; `archive` writes no ADR from `## Contracts` alone. Done-detection for the design artifact is unchanged (file exists, or `Skipped`), so `sk-status` and `ff` need no change
- **`tasks.md` is unchanged.** The test is a step inside a task, so no task, marker or status is added. `/sk:verify`, `sk-status` and the `pre-push` hook still read only `- [ ]` / `- [x]`, and the template's "Tests covering the scenarios" task is ticked once those tests exist
- Evals: `apply-implements-tasks` gains `writes-test-file` (a `Write` outside `sk/` to a test path, `min: 1`) and `no-false-test-claim` (LLM: the reply claims no test run, since the run has no shell). Measured with `--ablation none`, 3 runs: 1.00, $0.78. In every run the reply listed each scenario's test as "written, not run". Planned with three read-only research agents (source skill, apply/verify contracts, edge cases). Not verified: a real run with a shell, where the red → green loop actually executes
- Contracts measured (`--ablation none`, 3 runs, $12.07) across every case of the touched skills — `ff-*`, `continue-*`, `verify-*`, `archive-*`, `apply-*`, 16 cases: all above 0.8. `ff-writes-remaining-artifacts` gains `design-has-contracts` (regex `## Contracts` in `design.md`, since the change adds a public interface) and scored 1.00. Below 1.00: `continue-marks-ambiguous-ac` 0.83 (`selective-marking` 2/3 — the spec-delta step this change does not touch, the over-marking noted at 0.3.x) and `archive-asks-before-writing-adr` 0.93 (one judge FAIL on a `design.md` that has a `## Decision`, so not the Contracts rule)
- Independent review before merge, fixed: `apply`'s "working means the test passes" now carries `tdd.md`'s exception for a scenario spread over several tasks (the two read as contradictory); `playbook-mapping.md` still said design was only for a trade-off; `writes-test-file` had one backslash in `[\/]` where `writes-code-outside-sk` has two, so on Windows paths only the `.test.`/`.spec.` branch could match; `verify-passes-complete-change` said design was skipped while its change adds three exports — it now has a `design.md` whose `## Contracts` match the code, so the case also exercises the contract check; `verify` says a different body behind the same signature is not a contract difference; an export used only inside its module or by its own tests does not make design mandatory. Re-measured `apply-*`, `verify-*`, `ff-*` (5 cases, 3 runs, $4.67): all 1.00

## 0.7.0 — 2026-10-15

Optional git `pre-push` hook, set up by `/sk:init`, that stops a push when someone forgot `/sk:archive`. The only reminder was the close-out line of `/sk:apply`, and no skill is running when a person types `git push`.

- **What it stops.** The commits being pushed hold a change under `sk/changes/<id>/` whose `tasks.md` has every box ticked (the `/sk:verify` checkbox rule), or an `[[OPEN:Q<n>]]` marker inside `sk/specs/`. A change with any task still open passes, so work split over several PRs is not blocked. It reads the pushed commits (`git ls-tree` / `git show` on the pushed sha), not the working tree. `git push --no-verify` bypasses it once
- **Two files.** `sk/hooks/pre-push` holds the check and is committed, so the team shares one version and changes it by PR. A 4-line shim in the clone's hooks directory runs it, and is a no-op on a branch without `sk/`. `.git/hooks` is not cloned, so migration item 7 offers the shim to each teammate's clone
- **Never unattended, never over someone else's hook.** Offered only with the Bash tool and a person's yes, since it changes every later push and writes inside `.git/`. With `core.hooksPath` set (husky and the like) or an existing `pre-push`, `init` writes nothing there and prints `sh sk/hooks/pre-push "$@"` to add by hand
- **Archive before push** is now written down in the README: archiving inside the PR puts the `sk/specs/` diff next to the code that changed it. Nothing said when to archive before, which is what made "forgot to archive" undetectable
- Not a CI check, not a Claude Code hook. A Claude Code hook only sees pushes Claude makes, and `docs/PLAN.md` keeps hooks as approval gates out of scope. A pipeline check is the stronger guarantee (a local hook can be skipped) but needs a pipeline in every consuming repo — left for later
- Verified by hand in a temp repo with a bare remote: no `sk/` → pass; one task open → pass; all ticked (incl. `[ X ]`) → stopped; `[~]` → pass; marker in `sk/specs/` → stopped; fixed → pass; branch delete → pass; the script with CRLF line endings under Git Bash → still stops. Evals unchanged (29 cases): they have no Bash grant, so `init` skips the offer there
- Full gated run (`--ablation none`, 3 runs each, ≈ $20.5): `init` 1.00; `wi` failed on `continue-writes-spec-delta` 0.92 and `core` on `ff-writes-remaining-artifacts` 0.78. Both were the suite, not the skills:
  - `ac-faithfulness` gave Haiku a one-line paraphrase of each criterion, so a spec quoting the real text (the eight function names, "paste a sample value") read as invented. It also counted a scenario ending in `[[OPEN:Q<n>]]` as stated behaviour. The failing specs were faithful. The grader now holds the ten criteria word for word and says a marker states nothing
  - The `ff` fixture seeded three of the eight transform functions criterion 5 calls "currently available", and `character_limit` returned its input. `/sk:ff` rightly logged that as a Gap and stopped after the delta, 3/3, so `tasks.md` was never written. The earlier 1.00 was a run that missed the Gap. The fixture now has all eight
  - After the fix: both 1.00 (3/3). Other cases with a single FAIL run, above their threshold: `verify-passes-complete-change` and `archive-already-archived-drafts-records`, 0.93 each

## 0.6.0 / sk-status 0.1.1 — 2026-10-15

New `/sk:ff <change-id>`: writes every planning artifact a change is still missing (spec delta → design or its Skipped note → tasks) in one invocation, then stops before `/sk:apply`. Small work items went through three `/sk:continue` calls and three review stops, which cost more than they gave.

- **A separate skill, not a flag on `/sk:continue`.** `continue`'s one-artifact stop and its Planning boundary wording were measured against real violations (`continue-one-artifact-per-call`, `propose-does-not-auto-apply`); a flag would have meant rewording them. `continue`'s text is untouched
- **Only a person can start it.** `disable-model-invocation: true` keeps it out of the model's reach, so "finish all the remaining artifacts" still lands on `/sk:continue` and still produces one
- **No copy of the rules.** `ff` reads `continue` Step 3 from `skills/continue/SKILL.md` at run time for each artifact (AC-source refusal, re-fetch and U+FFFD check, open-question markers, `MODIFIED` restated in full, design only for a real trade-off), so the two cannot drift
- **Stops after the delta** when the delta has `## MODIFIED Requirements` — the easiest place to lose specification, so a person reviews it before tasks are built on it — or raised a Gap. Unresolved decidable tokens are marked, not a reason to stop
- **Where it is offered.** `/sk:propose`'s close-out names it as the alternative to `/sk:continue` for small items (one sentence, Planning boundary untouched). `sk-status` 0.1.1 adds an `f: Run /sk:ff` button at the spec, design and tasks steps, beside `n`; the Tab suggestion stays `/sk:continue`, since the mod cannot tell a small item from a large one
- README gains "Item nhỏ": the `ff` path, and the work that needs no `sk` at all — no change to observable behaviour (typo, refactor, dependency bump, a bug fix that restores what `sk/specs/` already says); a commit with `AB#<id>` is enough
- Evals: 28 → 29. New `ff-writes-remaining-artifacts` (`core`), seeded with `continue-one-artifact-per-call`'s fixture minus the spec delta. It has no `tool_used: Skill` grader: a `disable-model-invocation` skill is started by the slash command in the prompt, not the Skill tool. The runner does expand the slash command. Measured (1 run each, `--ablation none`): `ff-writes-remaining-artifacts` 1.00 ($0.54), `continue-one-artifact-per-call` re-run with `ff` present 1.00. Two earlier runs did the right thing but failed one LLM grader 3/3 both times — it bundled design, the `/sk:apply` hand-off and "without running it" into one judgement for Haiku, and the runner records no judge rationale. Replaced by a deterministic `apply-not-fired` (`tool_used`, same pattern as `propose-does-not-auto-apply`) plus a one-question `design-decided`

## sk-status 0.1.0 — 2026-10-13

New optional plugin `sk-status@simplify`, separate from `sk`: a Claude Code mod that shows where each change stands, because people forgot which `/sk:*` command came next and could not see a change's progress without opening its files.

- **Status line, Tab suggestion and `/sk-status` pane.** The status line names the most recently edited change, its step, task count, open questions and next command. After each turn the next command is offered as a Tab suggestion. The pane lists open changes (most recently edited first, `o` to order by progress), shows the selected change's pipeline, reads `proposal.md` / spec delta / `design.md` / `tasks.md` in place (`p` `s` `d` `t`), and runs the next command on `n`
- **State is read off disk, not stored.** Same rules as the skills: artifact order from `/sk:continue` Step 2, `AC source: none yet` → `/sk:propose`, the `/sk:verify` checkbox rule, `[[OPEN:Q<n>]]` markers, `archive/` excluded. A 4-second rescan picks up edits made outside Claude and writes state only when something changed
- **Read-only, and commands run only on a press.** It writes no file and never calls Azure DevOps. A press is the person's own request, the same as typing the command, so it does not cross the planning boundary, which forbids the *model* from chaining into `/sk:apply`. `/sk:archive`, the one destructive step, needs a second press in a confirmation box whose focus starts on Cancel. When the `sk` command cannot be found the press only fills the prompt
- **Kept out of `plugins/sk` on purpose.** Merging was weighed: a module that fails to load only skips its hooks, so the skills would survive on any Claude Code that supports mods. Three reasons decided it. It is unverified how a Claude Code older than mod support treats a `hooks.json` with `modules`, and the bad case is losing `sk` itself. Merged, it could not be turned off without turning off `sk`. And every mods-API fix would force an `sk` release. `sk` stays markdown-only
- **`sk` 0.5.1: `/sk:init` mentions it.** One line at the end of the close-out says `sk-status` exists, is optional, and how to install it. `init` never installs it. Without this the plugin is only findable by reading the README. No eval asserts the line
- Verified: `claude plugin validate` and `tsc --noEmit` pass; the pane was checked by hand on Claude Code 2.1.286 against a real change at the verify step. Not verified: whether `$.command.run` resolves the skill's name as `sk:<skill>` on every install (the fallback fills the prompt), the multi-change list against a real repository, and the Desktop / VS Code surfaces. Not covered by the eval suite

## 0.5.0 — 2026-10-12

`/sk:propose`, `/sk:archive` and `/sk:init` ask their rounds of questions through Claude Code's `AskUserQuestion` when it is available, instead of only as text.

- **New `reference/asking-the-user.md`**, shared by the three skills. Questions with discrete answers go through the tool, recommended answer first and labelled `(Recommended)`, at most 4 per call — a longer round is several calls but still one round. Anything the person must read to decide (draft ADR, glossary terms, migration text, the AC split) is shown as text before the call. Open questions (missing criteria, a replacement definition) stay in text
- **Hybrid, not mandatory.** The tool takes at most 4 questions of 2–4 options and is absent in headless runs and the eval runner, so the existing text format (`❓ G<n> … ➡️` in `propose`) remains the fallback. Unattended runs are unchanged: no tool call, questions printed, answers recorded `unconfirmed` / drafts skipped as before. No rule about *what* is asked or *when* a round ends changed; the "Planning boundary" wording is untouched
- The grilling step had always asked in text. Nothing recorded why; it was inherited from `mattpocock/skills`' `grilling`, which asks in text
- Evals unchanged (28 cases). No case allows `AskUserQuestion`, so the asking cases keep measuring the text fallback; the tool path is verified by hand in a real session

## 0.4.0 — 2026-10-07

New `/sk:verify`: a read-only check of a change's implementation against its own artifacts, between `/sk:apply` and `/sk:archive`. It fills the Stage 4 gap `reference/playbook-mapping.md` recorded ("There is no `/sk:verify` yet").

- **Adapted from OpenSpec's `openspec-verify-change`** (MIT): the three dimensions — Completeness (tasks, requirements backed by code), Correctness (scenarios handled and tested), Coherence (`design.md`, `sk/config.yaml` → `rules`) — the CRITICAL / WARNING / SUGGESTION severities, the "when unsure, rank lower" rule and graceful degradation. The CLI parts (`openspec status`, `openspec instructions`, store selection) are dropped; artifacts are read from disk as `/sk:apply` does
- **Two ideas from `mattpocock/skills`' `code-review`** (MIT): review the diff since a fixed point (default: the merge-base with the main branch) instead of keyword-searching the whole codebase, and report behaviour no requirement or task asked for — where scope `/sk:apply` should have surfaced shows up when it was absorbed. Without a shell it reads the code the tasks point at and says the scope check was skipped
- A ticked task with no code behind it is CRITICAL: the checkbox is the claim, verify is where it is checked. Open-question markers still in the delta are reported as CRITICAL because `/sk:archive` will stop on them, with every `(built on Q<n>)` task listed
- **Not a gate.** `/sk:archive` is unchanged and does not require it; verify does not repeat archive's merge checks (scenario count, conflicts), so the `MODIFIED` invariant still lives in exactly three places. It writes nothing, ticks nothing, and never invokes `/sk:apply` or `/sk:archive`
- `/sk:apply` now suggests `/sk:verify` before `/sk:archive`; `/sk:init` lists it in the section it appends to `CLAUDE.md` (existing workspaces need no migration — the skill is found by its description)
- Evals: 25 → 28 cases, all `core`, all asserting nothing is written or edited (reusing the write/edit-outside-`sk/` pattern whose canary is in `apply-implements-tasks`). `verify-reports-missing-requirement`: every task ticked, one of two requirements absent from the code → flagged critical, not ready for archive. `verify-passes-complete-change`: the same change actually finished → no critical issue, ready for archive; without it a verify that always says "not ready" would pass, and a reviewer whose alarms are false gets ignored. `verify-flags-open-question`: built and tested, but `[[OPEN:Q1]]` left in the delta → critical because `/sk:archive` stops on it, naming Q1 and the task built on it, without resolving it
- Measured once each (`--runs 1 --ablation none`, so a smoke test, not a rate): `verify-reports-missing-requirement` 1.00 (judge PASS×3; the transcript shows it read `conventions.md` through `${CLAUDE_PLUGIN_ROOT}`, announced the no-shell path, and scored 1/2 requirements), `verify-passes-complete-change` 1.00 (2/2 requirements, 3/3 scenarios, no critical), `verify-flags-open-question` 1.00 (Q1 critical at `spec.md:11`), and the regression/canary case `apply-implements-tasks` 1.00 (Write outside `sk/` 1×, so the reused pattern still matches); total ≈ $0.77
- Still manual: the shell path (diff, merge-base, the scope check, running the test command), which eval runs on Windows cannot reach
- Research behind the choice, and which other `mattpocock/skills` are worth adapting next: `docs/research/mattpocock-skills-integration.md`

## 0.3.0 — 2026-10-07

`/sk:propose` accepts a direct request, for work that has no work item — refactors, tech debt, spikes, or work not yet on the board. The work item path is unchanged.

- **New Branch R in `/sk:propose`.** Only when the user explicitly invokes the command with a request (`/sk:propose <request>`, "sk propose: …"); a feature described in ordinary conversation still starts nothing. That is what kept this out before — competing with other planning skills (`docs/PLAN.md` risk 6) — so the skill description is deliberately not widened to fire on any feature description. Change id is `req-<slug>`; a bare integer is still asked about as a possible PR id
- **Criteria must be the user's.** Criteria stated in the request are used as written (`**AC source:** user, in conversation`, text under `## Acceptance criteria not on the board`). When the request states none, `propose` suggests criteria as grilling questions; until a person confirms them `**AC source:**` stays `none yet`, the suggestions go under Gaps, and `/sk:continue` refuses a spec delta. This is the one exception to the unattended `unconfirmed` fallback: criteria nobody wrote are not a reading to review later
- `templates/proposal.md` gains `## Request` (the request verbatim — the only copy, since no board holds it) and a `**Work item:** none — direct request` form without the Type / State line. `/sk:continue` reads a direct request's criteria from `proposal.md` like any non-board source, and gives open questions to the user instead of "paste into the work item's comments". `/sk:archive` accepts the recorded request as the source for a glossary `_Avoid_` word. `/sk:init` mentions the new entry in its close-out. No workspace migration is needed
- Evals: 23 → 25 cases, both `core`. `propose-from-request` (criteria in the request → `user, in conversation`, request and criteria recorded) and `propose-request-without-ac-asks` (a wish with no criteria, unattended → `none yet`, no spec, suggestions not presented as agreed)
- Measured once each (`--runs 1 --ablation none`, so a smoke test, not a rate): `propose-from-request`, `propose-request-without-ac-asks` (judge PASS×3), and the regression cases `ignores-unrelated-request`, `propose-does-not-auto-apply`, `propose-from-work-item`, `propose-missing-ac-asks`, `continue-refuses-without-ac` all scored 1.00 (total ≈ $1.5)
- Still manual: whether an ordinary feature description in a real repository, with many skills installed, leaves `sk:propose` alone

## 0.2.0 — 2026-09-30

Planning is split into steps, after OpenSpec's `/opsx:continue`. `/sk:propose` used to write proposal, spec delta and tasks in one go, so the first thing a reviewer could check was a finished spec built on a reading of the acceptance criteria they had never seen.

- **Breaking: `/sk:propose` now writes `proposal.md` only.** It still fetches the work item, picks Branch A or B, and follows `Related` and parent links in Branch B. It no longer writes the spec delta, `design.md` or `tasks.md`
- **New `/sk:continue`** creates the next artifact — spec delta, then design, then tasks — and stops after one. There is no status command; what is done is read off the files on disk. `design.md` counts as done when it exists, or when `proposal.md` has a `## Design` section saying it was skipped and why
- `proposal.md` gains an `**AC source:**` line (`work item`, `related`/`parent` after confirmation, `user, in conversation`, or `none yet`). `/sk:continue` reads it to know where the criteria live, and refuses to write a spec delta while it says `none yet`. When the user supplied criteria that are not on the board, their text goes under `## Acceptance criteria not on the board`, because it is the only copy
- `/sk:continue` re-fetches the work item before writing the spec delta (REST, U+FFFD scan), since the board may have moved since `proposal.md` was written. It never starts a change: no `proposal.md`, no run
- The "Planning boundary" paragraph now exists in both skills, extended with "never a second artifact in the same invocation". Its wording was measured for `propose` before this split; the `continue` copy is **not yet measured**
- Evals: 13 → 16 cases (17 with the grilling case below). `propose-from-work-item` now asserts `proposal.md` exists, records `AC source`, and that no spec or tasks were written. The faithfulness, HTML-stripping and scenario graders moved to the new `continue-writes-spec-delta`; `propose-marks-ambiguous-ac` became `continue-marks-ambiguous-ac`; `propose-does-not-auto-apply` now also asserts neither `continue` nor `apply` fired. New: `continue-one-artifact-per-call` and `continue-refuses-without-ac`
- Measured once each (`--runs 1`, so a smoke test, not a rate): `propose-from-work-item`, `continue-writes-spec-delta`, `continue-one-artifact-per-call`, `continue-refuses-without-ac` and `propose-does-not-auto-apply` all scored 1.00 (total ≈ $1.4). The new `exists: false` graders on glob paths work. `ac-faithfulness` passed on a split judge vote (FAIL PASS PASS)
- **`continue-marks-ambiguous-ac` failed `selective-marking` (judge FAIL ×3) before the split too** (the original `propose-marks-ambiguous-ac` on `main` failed it identically in 2/2 runs). Resolved as a fixture fault, not a skill fault: the skill marked criteria 1 (visible rows: one page or all pages) and 2 (date time zone), and both genuinely pass the two-step test in `reference/conventions.md` — the source text permits a second value — while the grader claimed they were fully pinned down. The fixture now pins them (`across all pages of results`, `current UTC date`) so the grader's premise is true; the skill and the grader's pass/fail rules are unchanged
- **`/sk:propose` now grills before it decides** (new Step 4, after `mattpocock/skills`' `grilling`). It asks the whole frontier of open decisions in numbered rounds (`G1`, `G2`, … — not `Q<n>`, which is `/sk:continue`'s open-question numbering), each with a recommended answer, and writes `proposal.md` only once the user has confirmed the reading. The first round always happens, even for grouped bullets. When the request says nobody can answer, it writes the recommended answers and marks the `## Assumptions` entries `unconfirmed`; without that statement it asks and writes nothing. `confirmed`/`unconfirmed` is new in `templates/proposal.md`
- Evals: 16 → 17 cases. New `propose-grills-before-writing` (asks numbered questions with recommendations, writes nothing). `propose-from-work-item` and `propose-does-not-auto-apply` gained a sentence saying nobody can answer, because a run is one message and would otherwise stop at the questions
- Measured after the grilling step and the fixture fix (3 runs each unless noted; wi/init/core gates were cut short by the cost ceiling because the default also runs the without-plugin arm, so the remaining core cases were run with `--ablation none`): `propose-grills-before-writing`, `propose-does-not-auto-apply`, `propose-missing-ac-asks`, `propose-related-item-fills-gap`, `propose-related-item-is-noise`, `propose-parent-narrows-gap`, `ignores-unrelated-request`, `propose-from-work-item`, `continue-writes-spec-delta`, `continue-one-artifact-per-call`, `continue-refuses-without-ac`, the three `archive-*` cases and `init-sets-up-sk` all scored 1.00. `continue-marks-ambiguous-ac` went from 0/3 to 2/3 full passes (mean 0.89); the third run still over-marks criteria 2 and 5, which is run-to-run noise rather than a systematic fault
- **`apply-implements-tasks` scored 0/3 and was not caused by this change**: the same case on `002fc3c` also scored 0/3. `/sk:apply` stopped to ask because task 1.1 needed a list of system-defined attributes, and task 1.2 the group labels, that neither the fixture's proposal, spec nor code contained — correct under the no-fabrication rule, but the case expects it to implement (the without-plugin arm scored 1.00 by inventing the values). Fixed in the fixture by putting both into `tasks.md`; 3/3 at 1.00 afterwards. The skill is unchanged
- **`/sk:archive` now records what the merge would lose, and archived changes are no longer committed.** `/sk:init` appends `sk/changes/archive/` to `.gitignore` (never `sk/changes/` as a whole: open changes stay committed so teammates can review them and so `propose`/`archive` see each other's unarchived deltas). Because the archive is then local-only, `archive` drafts an ADR (`sk/adr/NNNN-<slug>.md`, only from an existing `design.md`, only when it is hard to reverse, surprising without context and a real trade-off) and glossary terms (`sk/context.md`, only terms the delta or proposal defines) and asks for confirmation before writing anything. Unattended, it merges and moves as usual, skips both and prints the drafts. `git mv` is no longer used when the archive is ignored — it would stage the archived copy despite the ignore rule — the change is copied and the original removed with `git rm -r`. Workspaces created before this must add `sk/changes/archive/` to `.gitignore` by hand; `archive` says so when the path is not ignored and falls back to `git mv`
- Evals: 17 → 19 cases. New `archive-asks-before-writing-adr` and `archive-skips-adr-unattended`; `init-sets-up-sk` gains two `.gitignore` graders; `archive-merges-spec` gained the unattended sentence. The directory move and the `git rm` path are not covered (runs have no shell) and need a manual pilot in a real repository
- Measured (3 runs each, `--ablation none`): `archive-asks-before-writing-adr`, `archive-skips-adr-unattended`, `archive-merges-spec`, `archive-rejects-scenario-loss`, `archive-blocks-open-question` and `init-sets-up-sk` (with its two new `.gitignore` graders) all scored 1.00 (total ≈ $3.7)
- **`/sk:init` migrates workspaces made by 0.1.x** instead of refusing when `sk/` exists. It detects by what is on disk, not by a version number (there is none in `sk/`). It appends only and never touches `config.yaml`: the `.gitignore` entry; a `## Design` "Skipped" section on open changes that have `tasks.md` but no design (else `/sk:continue` would write a `design.md` for a change already planned, possibly built); `**AC source:** none yet` on open changes with no spec delta. It only reports — never runs — `git rm -r --cached sk/changes/archive` (it changes teammates' checkouts) and the archived changes that have a `design.md` (record their ADRs first). With a person it shows the plan and asks once; unattended it applies the three append-only items and prints the rest. Evals: 19 → 21 cases (`init-migrates-old-workspace`, `init-asks-before-migrating`); the `git rm` path stays manual
- Measured (3 runs each, `--ablation none`): `init-migrates-old-workspace`, `init-asks-before-migrating` and `init-sets-up-sk` all scored 1.00 (total ≈ $1.5)
- **`/sk:archive` records mode, after a real-repo run showed the gap.** Running `/sk:archive <id>` on an already-archived change validated, found the spec already merged, stopped at "already archived" and only offered to read the proposal if asked — because the records step was documented as needing a request that names an ADR or glossary. An id already under `archive/` now goes straight to records mode (no validation, merge or move; `sk/specs/` untouched), and `/sk:archive backfill` covers every archived change in one pass: one deduplicated glossary draft (a term defined differently by two changes is asked, never picked), an ADR per change whose `design.md` qualifies, one question for the whole batch. `init` item 5 now points at `backfill` instead of listing ids to run one by one. Evals: 21 → 23 cases (`archive-already-archived-drafts-records`, `archive-backfill-all`)
- Measured after records mode (3 runs each, `--ablation none`): `archive-already-archived-drafts-records`, `archive-backfill-all`, `archive-skips-adr-unattended`, `archive-merges-spec`, `archive-rejects-scenario-loss`, `archive-blocks-open-question`, `init-migrates-old-workspace` and `init-asks-before-migrating` scored 1.00. **`archive-asks-before-writing-adr` scored 0.80 (0/3, judge FAIL×3 on `drafts-adr-and-asks`) in that batch, then 6/6 at 1.00 on two immediate reruns (1 + 5 runs) with identical code.** Not explained: the passing replies show the full draft ADR and ask as required, and nothing in `plugins/sk/` changed between the batch and the reruns. Treat as unresolved variance, not as fixed; rerun it in CI-like conditions before trusting it
- Still unmeasured: the `continue` planning-boundary wording under adversarial requests (only `propose`'s was measured at scale), and the design-skipped path

## 0.1.1 — 2026-09-29

Work items are read over REST instead of the `az` CLI, after a pilot on the real
org found corrupted characters reaching a generated spec.

- `az boards work-item show` returns 9 replacement characters and 0 real em
  dashes on a real work item; REST with an access token returns 0 and 9. Setting
  `chcp`, `PYTHONIOENCODING`, `PYTHONUTF8` or `Console.OutputEncoding` does not
  help — the corruption is in what `az` writes
- `az devops invoke --area wit --resource comments` fails with an
  extension-internal `TypeError` on every work item, so comment reading had
  never run. REST reads them
- `propose` now refuses to write a spec containing U+FFFD, which also catches a
  later regression back to the `az` path

`propose` no longer treats its planning boundary as overridable. A request that
asks to plan *and* build in one go used to carry some runs straight into
implementation — the model wrote project code, ticked tasks, and explained in its
own words that it was continuing because the request said the work was urgent.

- The guardrail refuses at the level of *reason category* rather than listing
  phrases, and states that an explanation for why continuing is fine this time is
  the guardrail failing, not an exception to it
- Measured on `propose-does-not-auto-apply`: 4 violations in 20 valid runs before,
  0 in 30 runs after, across appeals to urgency, to having no second turn, to
  authority, and to planning not mattering much. That rules out a true rate at or
  above 10%; it does not separate 0% from a few percent
- New eval case covers behaviour no per-skill case reached — one request spanning
  two skills' territory must still produce only one of them. It is the expensive
  one: $2.68 per default invocation against $0.16 for the cheapest case
- `ignores-unrelated-request` gains a `case.yaml`, so `name`/`tags` live in one
  place across all eight cases. `prompt.md` frontmatter is read for tags as well,
  which is now recorded in the suite's gotchas

`README.md` gains a "Khái niệm cốt lõi" section — the vocabulary (Spec, Change,
Requirement, Scenario, Delta, Proposal, Archive) was only ever introduced piecemeal
across the workflow walkthrough; a reader arriving cold had nowhere to look it up
in one place. Modelled on OpenSpec's `docs/concepts.md`.

`propose` now follows a `Related` link when a work item's own acceptance
criteria are missing or too thin (Branch B), instead of asking a blank
question while the answer sits one hop away on the board. `relations[]` was
already fetched on every read but nothing before this consumed the `Related`
entries in it.

- Only fires in Branch B — a work item with usable AC of its own never reads
  a related item, to keep the no-fabrication guardrail intact for the
  four-in-five stories that already have what they need
- Bounded the same way the Task→parent cascade already is: at most 3
  `Related` items, one hop (a related item's own `relations[]` is not
  followed), and `Hierarchy-Forward` (children) is still skipped regardless
  of type. For a `User Story` or `Bug`, that's because children are
  typically `Task`s with no acceptance criteria of their own; a `Feature`'s
  children are usually `User Story` items that do carry their own AC, but
  this fix does not follow them — that's a known gap, not a case this rule
  claims to cover
- A related item's content is never written to `specs/` on its own say-so —
  it only sharpens the question Branch B asks, naming the item and what it
  says. `proposal.md` names it in the Gaps section as soon as it is read,
  marked as a pending confirmation, whether or not the user has answered
  yet; only the user's confirmation moves that entry from Gaps to a note
  recording the source
- If the related item's content doesn't actually bear on the gap — a
  different surface, a stray bug report — the instructions now say
  explicitly not to manufacture a confirmation question out of it; Branch B
  falls back to its plain "what are the acceptance criteria?" ask instead
- New eval case `propose-related-item-fills-gap`: a work item with no AC,
  `Related` to one that has full AC. Asserts the reply names the related item
  and asks for confirmation rather than asserting its content as fact, that
  `proposal.md` records it in Gaps, and that no `spec.md` is written without
  that confirmation — the same single-turn boundary `propose-missing-ac-asks`
  already checks, extended to prove a plausible related item does not bypass
  it
- New eval case `propose-related-item-is-noise`: the mirror case, where the
  only `Related` item is unrelated in substance. Asserts the reply does not
  present that item's content as though it might answer the gap

`propose` now also follows a `Hierarchy-Reverse` (parent) link in Branch B
when the current item is **not** a `Task` — the shipped `Related` fix above
did nothing for a `User Story` whose only connected items are a parent
`Feature` and a child `Task`, with no `Related` entry at all. That shape is
what the previous fix was believed to cover and did not; measured on a new
eval case, the pre-fix instructions asked a blank question or offered to
read the parent without reading it in 3/3 runs (case score 0.75, 0/3 passed);
the fix reads the parent and asks an informed question in 3/3 runs (case
score 1.0, 3/3 passed)

- Gated on Branch B firing and the item not being a `Task` — a Task's parent
  is already read unconditionally in the fetch step, and this rule does not
  re-run on top of that
- Bounded to one hop, the same as the `Related` rule: the parent's own
  `relations[]` is not followed, and a thin parent is a dead end here, not a
  reason to go up to a grandparent
- Unlike a `Related` item, a parent's content is never offered as something
  to confirm as this item's own acceptance criteria wholesale. A `Feature`
  describes broader scope than any one item under it, so lifting its AC
  wholesale onto a `User Story` would over-scope the story — the fix asks a
  narrowing question instead (what part of the parent's scope this item
  covers) and writes what the user answers, not the parent's text verbatim
- Still a known, separate gap: a `Feature` input's own children
  (`Hierarchy-Forward`), which are typically `User Story` items carrying real
  AC, are not read. This fix adds the opposite direction of traversal
  (`Hierarchy-Reverse`) and does not close that gap
- New eval case `propose-parent-narrows-gap`: a `User Story` with empty
  description, no AC field, and no `Related` link, under a `Hierarchy-Reverse`
  parent `Feature` with real content and a `Hierarchy-Forward` child `Task`.
  Asserts the reply names the parent, uses its content to ask a narrowing
  question rather than a blank one, and does not lift the parent's
  acceptance criteria wholesale as the story's own; regression-checked
  against `propose-related-item-fills-gap`, `propose-related-item-is-noise`
  and `propose-missing-ac-asks` (3/3 each, no change)

Acceptance criteria that read as decided but are not — no retry count, no
threshold for "very large" — used to pass through `propose` as confident
`SHALL` sentences, get built, and merge into `sk/specs/` as requirements
nobody agreed to. The Gaps route never caught them: Gaps takes what you
*cannot* turn into observable behaviour, and an undecided threshold can be
turned into one by picking a number.

- An unresolved value is now marked inline in the sentence with a fixed
  literal token, leaving the position **empty** rather than filled with a
  guess. A filled placeholder ("a threshold to be determined") still reads as
  a complete claim, so removing it without answering leaves a plausible,
  wrong sentence; an empty slot leaves a visibly broken one
- `propose` never stops for it. Marking is a per-criterion step inside
  Branch A, not a third branch and not a reason to fall back to Branch B: a
  skill command is one turn, so stopping to ask is stopping, and the person
  who owns the threshold is not in the conversation
- `archive` is the only blocker, and its Phase 1 now reads
  `reference/conventions.md` — the check runs second, right after the
  finished-tasks check, because it is the cheapest one here and the one whose
  consequence is irreversible: a marker that reaches `sk/specs/` stops being
  a flagged gap and becomes an ordinary requirement
- `apply` does not block. It builds against the reading recorded under
  `## Assumptions` and notes `(built on Q<n>)` on the task, so whoever later
  overturns that answer can find what leaned on it. Blocking there would
  stall a whole checklist on one open threshold — `tasks.md` has no
  dependency graph to say which tasks could safely proceed
- The token is spelled in exactly one file, `reference/conventions.md`; the
  skills refer to it by role and never re-spell it. Two copies across the
  `propose`→`archive` seam would be free to drift apart, and nothing in the
  suite would catch it
- A `THEN` naming none of the seven decidable-token kinds is not a scenario
  with an open question in it — it is prose, and goes to Gaps. This is what
  stops "SHALL handle large catalogs appropriately" from acquiring a marker
  and looking like progress
- Unresolved tokens are sorted before they are marked: one answerable by
  lookup (`sk/specs/`, `sk/config.yaml`, or the item repeating the choice)
  is decided and recorded as an assumption; only a product decision gets a
  marker. Marking everything would make the `archive` block fire constantly
- A comment now beats the **acceptance criteria** as well as the description
  (`reference/azure-devops.md`), so a criterion a comment already settled is
  not reported as undecided
- Re-running `propose` on an existing change sweeps **every** `## Assumptions`
  entry, not just open ones — a comment posted since the last run can reverse
  a resolution that already looked settled, which reopens the slot. Already
  ticked tasks are never unticked; a new task records what needs re-checking
- Two eval cases: `propose-marks-ambiguous-ac` (AC mixing three pinned-down
  criteria with two undecided — asserts the undecided ones carry the marker,
  the pinned-down ones do not, and a real spec is still produced) and
  `archive-blocks-open-question` (a change valid in every other way — all
  tasks ticked, `ADDED` only, no name collision — so the open question is the
  only thing to stop for)
- **Not covered by any grader: detection recall.** No check can assert "you
  should have noticed this was ambiguous", and nothing blocks ambiguity that
  was never recorded in the first place. Making the seven token kinds a
  walked checklist turns the failure from "didn't notice" into "skipped a
  category", which is easier to review — it does not eliminate it
- Also uncovered, for the structural reason already recorded in the suite's
  own limits: anything needing a second user turn. Re-running `propose` to
  reopen a reversed resolution, filling a slot from an off-board answer, and
  `apply` building on a marked delta are all verified by hand, not here. The
  single-spelling rule is likewise not an eval — it is a static invariant,
  checked with a `grep` for the token outside `reference/conventions.md`,
  the templates and the graders

## 0.1.0 — unreleased

First round. Four commands: `/sk:init`, `/sk:propose`, `/sk:apply`, `/sk:archive`.

- Spec-driven artifacts under `sk/`, modelled on OpenSpec's requirement/scenario format
- `/sk:propose` reads an Azure DevOps work item — full org URL, `--expand all`, HTML stripped, comments read, Task cascaded to parent — and turns acceptance criteria into a spec delta. Read-only against ADO
- Branch for work items whose acceptance criteria are missing: ask, never generate a spec from an empty field
- `/sk:archive` validates every capability before writing anything, and stops rather than reconciling conflicting deltas
- Eval suite under `plugins/sk/evals/`

### Pre-push checklist

- [x] **Fixture sanitisation reviewed.** The work item payloads live in the heredocs inside `plugins/sk/evals/**/fixture.sh` — there are no standalone `.json` fixtures, so grepping for those finds nothing and proves nothing. Checked: no personal names, emails, customer names or contract identifiers; org URLs and work item ids replaced with invented ones. The fixtures keep the HTML *structure* of real work items on purpose, which is the part worth reviewing again whenever one is added.

  The deadline for this is **before anyone installs**, not before the repo gets a remote: `evals/` ships inside the plugin, so every install copies the fixtures onto another machine.

- [x] **`propose-does-not-auto-apply/fixture.sh` reviewed** when it was added. Work item 20700 and its low-stock badge story are invented; org `example-org.visualstudio.com` and project `CatalogPortal` match the invented names already used elsewhere. No personal names, emails, customer names or contract identifiers.

- [x] **`propose-related-item-fills-gap/fixture.sh` reviewed** when it was added. Work items 20800 and 20801 and their bulk-export story are invented; org and project match the invented names already used elsewhere. No personal names, emails, customer names or contract identifiers.

- [x] **The three `verify-*/fixture.sh` reviewed** when they were added. They carry no work item HTML: `us-12345-field-selector` reuses the invented change from `apply-implements-tasks`, and work item 20001 with its CSV-retry story is invented, after `archive-blocks-open-question`. Org and project match the invented names already used elsewhere. No personal names, emails, customer names or contract identifiers.

- [x] **`propose-related-item-is-noise/fixture.sh` reviewed** when it was added. Work items 21000 and 21001 and their expiry-filter/dark-mode stories are invented; org and project match the invented names already used elsewhere. No personal names, emails, customer names or contract identifiers.

- [x] **`propose-parent-narrows-gap/fixture.sh` reviewed** when it was added. Work items 21200, 21201 and 21202 and their catalog-sync-migration story are invented; org and project match the invented names already used elsewhere. No personal names, emails, customer names or contract identifiers.
- [x] **Fixtures added or changed with the grilling, ADR and migration work reviewed:** `propose-grills-before-writing`, `archive-asks-before-writing-adr`, `archive-skips-adr-unattended` (copies of the 12345 fixture plus an invented `design.md`), `init-migrates-old-workspace` and `init-asks-before-migrating` (work items 12345, 20600, 10000 and an invented 0.1.x workspace), and the edits to `continue-marks-ambiguous-ac` and `apply-implements-tasks`. All names, ids and data are invented; org and project match those already used. No personal names, emails, customer names or contract identifiers.
