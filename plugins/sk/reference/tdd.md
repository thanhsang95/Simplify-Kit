# Test-first in `/sk:apply`

Each `#### Scenario` in the change's spec delta gets a test that fails before its code exists and passes after — the cheapest proof that a ticked box means what it claims. Adapted from `mattpocock/skills`' `tdd` (MIT): red before green, one slice at a time, a public seam, expected values from an independent source.

## The seam is the scenario

- One test (or a few, for several `THEN`/`AND` outcomes) per scenario. The scenario was already reviewed, so **never ask the person to confirm seams** — it would block every unattended run
- Test through the `design.md` → `## Contracts` interface exactly as written. Code that needs a different signature is a hole in the design: stop and ask. Without a contract, test through the public interface a caller uses — never private internals, never mocks of code this repository owns; mock only at the system boundary (external services, clock, randomness)
- Expected values come from the scenario's literals and `THEN` wording — never computed the way the code computes them, or the test passes by construction
- Name the test after the behaviour, close to the scenario's words, so `/sk:verify` can match them
- Put it where the repository keeps tests, in its framework. The command is the `Test:` line in `sk/config.yaml`'s `context`

## The loop, per scenario

1. Before the first task touching the scenario, write its test
2. Run just that test and **read the failure**: it must fail because the `THEN` is not met. A missing import or typo is not red — fix the test
3. Do the task(s), only what the scenario needs
4. Run it again; it must pass. Then tick

A scenario spread over several tasks stays red until its last: earlier tasks tick when their named part works, the last only when the test passes.

**Passes before the code exists** → the behaviour already exists (say so; the task may be unneeded) or the test misses the `THEN` (fix it). Never report it as red.

**Will not pass** after a reasonable attempt → a blocker: stop and ask. Never loosen, skip, or tick past it.

## A change from a Bug

`proposal.md` then has a `**Symptom:**` line (the actual result) and `## Repro steps`. The scenarios with the Bug's expected result are the reproduction: no fix before a test that is red for the reported reason.

- **Red means the symptom.** Setup from the scenario's `GIVEN`/`WHEN` and `## Repro steps`, expected value from its `THEN`. It must fail *showing the symptom*; any other failure is a different bug or a broken test
- **Green before the fix means not reproduced** — the test misses the triggering conditions. Narrow toward the data, order and configuration `## Repro steps` names. Never fix on a guess; still not reproducing → stop and ask, saying what was tried
- **Minimise once red**: drop setup one element at a time while it still fails with the symptom. The smaller test is the regression test
- **Linked test cases** under `## Test cases` can supply setup the repro steps omit; expected values still come from the scenario
- **Name the cause in the close-out** — one line, what was wrong and where — and whether the failure matched the symptom. It is the only record of the root cause

`Symptom: none stated` → red is read as for any scenario, and the close-out says so. No shell → write the test, and say the Bug was **not reproduced** here — different from fixed.

## When a test cannot be run

Without Bash (eval runs, restricted sessions), still write the test, but do not run it and **never write "saw it fail" or "it passes"**. Tick by the usual rule and list the tests written but not run.

## When there is nothing to test with

No test setup means the `Test:` line is missing, empty or still `<command>`, **and** the repository holds no tests or test framework configuration. A filled-in `Test:` line counts as setup.

- Never install a framework, add a dependency, or invent a command
- With a person present, ask once, before the first task
- Nobody can answer → skip test-first and say so, with the reason. Never silently

## What gets no new test

- **Tasks that change no behaviour** — docs, configuration, migrations, wiring
- **Scenarios not testable automatically** — layout, "no deployment needed", what does *not* change: no fake test; say which and why
- **`## REMOVED Requirements`** — remove their tests with the code
- **`## MODIFIED Requirements`** — test only the scenarios whose behaviour changed; run the existing tests for the rest
- **An existing test turning red** — update it if the delta changed that behaviour; otherwise the code is wrong, never the test
- **A task that only asks for tests** the loop already wrote — tick it; do not write them twice

## Scenarios with an open question

Test against the reading under `## Assumptions`, like the code, and keep the `(built on Q<n>)` note. A marker standing exactly where the asserted value goes, with no assumption pinning it → stop and ask rather than invent the number.

## What this never changes

`tasks.md` gains no task, marker or status — `/sk:verify`, `sk-status` and the `pre-push` hook read only `- [ ]` / `- [x]`. A scenario no task covers is missing scope: surface it and suggest `/sk:continue`. Refactoring is not part of this loop.
