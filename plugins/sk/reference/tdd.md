# Test-first in `/sk:apply`

How `/sk:apply` writes tests: each `#### Scenario` in the change's spec delta gets a test that fails before the code for it exists and passes after. Adapted from `mattpocock/skills`' `tdd` (MIT): red before green, one vertical slice at a time, test at a public seam, expected values from an independent source.

This exists because the spec already says, scenario by scenario, what the code must do, and nothing tied the two together. A test written from the scenario before the code is the cheapest proof that the ticked box means what it claims.

## The seam is the scenario

- One test (or a few, for a scenario with several `THEN`/`AND` outcomes) per `#### Scenario`. The scenario was reviewed with the spec delta, so the seam is already agreed. **Do not ask the person to confirm seams again**: the source skill does, but here it would block every unattended run for a question the spec review already answered
- Test through the interface `design.md` → `## Contracts` names for that scenario, exactly as written there — a person reviewed it before any code. When the code turns out to need a different signature, stop and ask (a hole in the design); never test against a contract you changed on your own. With no contract (design skipped, or no contract serves the scenario), test through the existing public interface the scenario describes — the function, endpoint, component or command a caller uses. Never against private internals, and never by mocking code this repository owns; mock only at the system boundary (external services, clock, randomness)
- Expected values come from the scenario: its literals, its examples, the `THEN` wording. Never compute the expected value the way the code does, or the test passes by construction and proves nothing
- Name the test after the behaviour, close to the scenario's own words, so `/sk:verify` can find which test covers which scenario
- Put it where the repository already keeps tests, in its framework and naming. `sk` defines no test runner; the command is the `Test:` line in `sk/config.yaml`'s `context`

## The loop, per scenario

1. Before the first task that touches the scenario, write its test
2. Run it — the narrowest command that runs just that test — and **read the failure**. It must fail because the `THEN` is not met yet. A failure from a missing import, a typo or a missing file is not red: fix the test and run again
3. Do the task(s). Implement only what the scenario needs
4. Run the test again; it must pass. Then tick, by the usual rule in `apply`

A scenario split over several tasks stays red until its last task: tick the earlier tasks by the usual rule (the part each task names works), and tick the task that completes the scenario only once its test passes.

**A test that passes before the code exists** means either the behaviour is already there — say so in the close-out, it may mean the task is not needed — or the test does not check the `THEN`. Fix the test; never report it as red.

**A test that will not pass** after a reasonable attempt is a blocker: stop and ask, as `apply` says for anything that errors. Never loosen the assertion, skip the test, or tick the task to get past it.

## A change from a Bug

`proposal.md` has a `**Symptom:**` line — `/sk:propose` writes it only for a Bug or a Task under one — holding the actual result the reporter saw, and a `## Repro steps` section with the steps. The scenarios carrying the Bug's expected result are the reproduction: no fix before a test that is red for the reported reason.

- **Red means the symptom.** Build the test's setup from the scenario's `GIVEN`/`WHEN` and `## Repro steps`; take the expected value from its `THEN` as usual. Run it and read the failure: it must fail *showing the symptom* — the wrong value, the error, the crash the `**Symptom:**` line describes. A failure for any other reason is a nearby bug or a broken test, not this one
- **Green before the fix means not reproduced.** For a feature, a test that passes early may mean the behaviour already exists. For a Bug it means the test misses the conditions that trigger it. Narrow toward what `## Repro steps` names — the data, the order of steps, the configuration — until it fails with the symptom. Never fix code on a guess about a failure you have not seen; when it still will not reproduce, stop and ask, saying what was tried
- **Minimise once it is red.** Remove one setup element at a time while the test still fails with the symptom, so what remains is what the failure needs. The smaller test is the regression test that stays
- **Linked test cases** listed under `## Test cases` in `proposal.md` can supply setup the repro steps leave out — their quoted actions. Expected values still come from the scenario
- **Name the cause in the close-out** — one line, what was wrong and where — and whether the failure you saw matched the symptom. That line is the only record of the root cause: `sk` adds no artifact for it

When the Symptom line says `none stated`, there is no symptom to match: red is read as for any scenario (it fails because the `THEN` is not met), and the close-out says so.

With no shell, write the test from the scenario and the symptom, and say in the close-out that the Bug was **not reproduced** here, which is different from fixed.

## When a test cannot be run

Running needs a shell. When the Bash tool is not available (eval runs, restricted sessions), still write the test from the scenario — that part needs no shell — but do not run it, and **never write "saw it fail" or "it passes"** about a run that did not happen. Tick by the usual rule and list, in the close-out, the tests written but not run. This is the same honesty `/sk:verify` keeps: "say the tests were not run and why".

## When there is nothing to test with

The repository has no test setup when the `Test:` line in `sk/config.yaml` is missing, empty or still the template's `<command>`, **and** the repository holds no tests and no test framework configuration.

- Never install a test framework, add a dependency, or invent a test command to get one
- With a person present, ask once, in Step 3, before the first task — not per task
- When nobody can answer, skip test-first for this change and say so in the close-out, with the reason. Never skip it silently

A `Test:` line that is filled in counts as setup even when its runner cannot be seen from here.

## What gets no new test

- **Tasks that change no behaviour** — docs, configuration, a migration script, wiring the task names: no test step
- **A scenario that cannot be tested automatically** — layout, "no deployment needed", a guarantee about what does *not* change: write no fake test. Say in the close-out which scenario was not tested and why
- **`## REMOVED Requirements`** have no scenarios: remove the requirement's tests along with its code; write none
- **`## MODIFIED Requirements`** restate every scenario, changed or not. Write or update tests only for scenarios whose behaviour changed; for the unchanged ones, find and run the existing tests
- **An existing test turning red** because of behaviour the delta changed: update it to the new scenario. If the delta did not change that behaviour, the code is wrong — never edit the test to match
- **A task that only asks for tests** of scenarios the loop already covered (the template's "Tests covering the scenarios this change added"): tick it once those tests exist; do not write them twice

## Scenarios with an open question

A scenario carrying the open-question marker is tested against the reading recorded under `## Assumptions` in `proposal.md`, like the code is, and the task keeps its `(built on Q<n>)` note. When the marker stands exactly where the asserted value goes and no assumption pins it, stop and ask rather than invent the number.

## What this never changes

- `tasks.md` gains no task, marker or status. The test is a step inside a task, not a task. A scenario no task covers is missing scope: surface it and suggest `/sk:continue`, as `apply` already says for scope growth. `/sk:verify`, the `sk-status` plugin and the `pre-push` hook all read only `- [ ]` / `- [x]`
- Refactoring is not part of this loop; `/sk:verify` reviews the result
