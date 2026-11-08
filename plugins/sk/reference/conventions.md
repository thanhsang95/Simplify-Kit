# Spec conventions

How SimplifyKit writes specifications. Read by `/sk:propose`, `/sk:continue` and `/sk:archive`.

## Where specs live

```
sk/specs/<capability>/spec.md                the living spec — what the system must do today
sk/changes/<id>/specs/<capability>/spec.md   a delta against it
sk/adr/NNNN-<slug>.md                        a design decision: hard to reverse, surprising, a real trade-off
sk/context.md                                the glossary of terms specific to this project
```

Only `/sk:archive` writes `sk/specs/`, `sk/adr/` and `sk/context.md`. `sk/changes/archive/` is not committed, so these are all that remain of a change — written from its artifacts, never invented, and only after a person saw the draft.

## Capability names

A slice of behaviour a reader recognises as one thing — `field-selector`, `catalog-download`, `edi-inbound`. Not a layer, a file or a sprint. Reuse a name already under `sk/specs/` when one fits; nest only where the project already nests (`identity/user-auth`).

## Requirements and scenarios

```markdown
### Requirement: Field selector includes product attributes

The field selector SHALL offer product attributes alongside standard fields.

#### Scenario: Attributes appear as their own group

- **WHEN** an administrator opens the field selector
- **THEN** attributes SHALL appear under their own heading, below standard fields

#### Scenario: Search spans both groups

- **WHEN** an administrator types into the field selector's search box
- **THEN** both standard fields and attributes SHALL be filtered
```

- A requirement states a **contract** — one SHALL sentence, in product terms
- A scenario states **observable behaviour** — `WHEN`/`THEN`, `GIVEN` when a precondition matters, `AND` for further results
- What the system does, not how it is built. Mechanism goes in `design.md`; the code-level interface (signature, endpoint, props) in `design.md` → `## Contracts`
- A requirement with no scenario is a wish. A scenario nobody could check is prose
- There is **no target ratio** between requirements and scenarios

## Ambiguous acceptance criteria

Some criteria read as decided but leave a value open. This section defines the mark, in exactly one place; whether a skill stops for it is the skill's call.

### The open-question marker

Mark an unresolved point inline with the literal token `[[OPEN:Q<n>]]` (`Q1`, `Q2`, … within the change), exactly where the undecided value would sit, so the sentence visibly fails to read:

```
- **THEN** the account SHALL lock after [[OPEN:Q2]] failed attempts
```

Not "after a threshold of failed attempts to be determined" — that still parses as a decision, and weeks later someone mistakes it for one.

`[[OPEN:Q<n>]]` is a fixed literal: never vary the brackets, prefix or spacing, and never invent a second phrasing — graders and tools match it with a plain regex.

### The two-step test

Per scenario, not per requirement.

**Step 1 — name the decidable token the `THEN` turns on.** Walk every scenario through all seven kinds, as a checklist:

1. a number or threshold
2. a comparison operator or boundary (`<` vs `<=`, inclusive vs exclusive)
3. a sort key and its direction
4. a set boundary (`only`, `all`, `except`)
5. an actor or a permission
6. a user-facing display string
7. behaviour on empty, absent, or error input

Quote the source text that pins it.

**Step 2 — try to write one other concrete value the same source text still permits.** If one fits, the token is unresolved. If the source allows only one value, write it — no marker.

### The floor: no decidable token, no scenario

A `THEN` naming none of the seven kinds is prose ("SHALL handle large catalogs appropriately"). It gets no marker; it goes in Gaps.

### Sorting a token: assumption or open question

- **An existing convention** — answerable by lookup: a pattern in `sk/specs/`, a value in `sk/config.yaml`, the work item repeating the choice, or a linked test case's expected result stating the exact value (`pins <what>` in `## Test cases`). Write the value and record it under `## Assumptions` with its source. No marker
- **A product decision** — a business threshold, a permission, user-facing wording — no lookup answers. Write `[[OPEN:Q<n>]]` and record `Q<n>` under `## Open questions`

A Gap is a criterion the AC does not cover at all; an open question is one it covers, just not down to one value. They live in different sections and are resolved differently.

## Turning acceptance criteria into a spec

**Infer the mapping from the shape the author used** — never a fixed "one criterion, one scenario", which inflates or collapses real criteria.

- **Grouped bullets** — the heading is the requirement, the bullets its scenarios. Nothing to record
- **Given/When/Then sentences, ungrouped** — each sentence is a scenario; gather those about the same behaviour into a requirement you name
- **Prose** — split by observable behaviour, and **write the split down** in `proposal.md` so a reviewer can disagree with the split itself
- **A Bug's repro steps** — steps as `GIVEN`/`WHEN`, each distinct expected result a `THEN`. The actual result never enters the spec: it is what the system must stop doing. `ADDED` unless an existing requirement says otherwise, then `MODIFIED`, restated in full
- **Test case results confirmed as criteria** — actions as `WHEN`, expected results as `THEN`. Keep the observable action ("submits the form with an empty name"), drop the route ("clicks Save in the toolbar")

Whatever the shape: a criterion with no observable behaviour goes in **Gaps** and you ask; never invent a scenario to round out a requirement — a spec that says things nobody asked for is worse than an honest gap; strip HTML first (`azure-devops.md`).

## Delta sections

Only these three headings; omit any you are not using:

```markdown
## ADDED Requirements
## MODIFIED Requirements
## REMOVED Requirements
```

### `MODIFIED` restates the entire requirement

**A requirement under `## MODIFIED Requirements` must contain its full body: every scenario, including the ones this change does not touch.**

`/sk:archive` replaces the matching requirement in `sk/specs/` with what the delta holds. Write only the changed scenario and the rest is deleted — names still match, no conflict is reported, and the loss surfaces only when someone later asks what that requirement covers.

Method: copy the requirement out of `sk/specs/<capability>/spec.md`, then edit the copy.

`/sk:archive` stops and asks when a merged requirement has fewer scenarios than the one it replaces. That net catches the common case, not every case — swapping one scenario for another keeps the count. Restating in full is the actual guarantee.

### `ADDED` and `REMOVED`

- `ADDED` — must not already exist in `sk/specs/`; if it does, a person resolves the conflict
- `REMOVED` — name the requirement exactly and say in one line why it goes. No scenarios
