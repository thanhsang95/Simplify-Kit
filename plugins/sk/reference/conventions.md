# Spec conventions

How SimplifyKit writes specifications. Read by `/sk:propose` and `/sk:archive`.

## Where specs live

```
sk/specs/<capability>/spec.md          the living spec — what the system must do today
sk/changes/<id>/specs/<capability>/spec.md   a delta against it
```

`sk/specs/` is written only by `/sk:archive`. Nothing else edits it.

## Capability names

A capability is a slice of behaviour a reader would recognise as one thing — `field-selector`, `catalog-download`, `edi-inbound`. Not a layer (`services`), not a file, not a sprint.

Reuse an existing capability path when one fits: `sk/specs/` is the list of names already in play. Nest only when the project already nests (`identity/user-auth`).

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

Rules that matter:

- A requirement states a **contract** — one SHALL sentence, in product terms
- A scenario states **observable behaviour** — what a person or a caller can see. `WHEN`/`THEN`, with `GIVEN` when a precondition matters and `AND` for further observable results
- Write what the system does, not how it is built. Mechanism belongs in `design.md` unless the mechanism itself is the contract
- A requirement with no scenario is a wish. A scenario nobody could check is prose

There is **no target ratio** between requirements and scenarios. One requirement with one scenario is fine; one with eight is fine.

## Ambiguous acceptance criteria

Some acceptance criteria read as decided but aren't — no threshold, no comparison operator, no sort order, no set boundary, no owner, no wording, no empty-state behaviour. This section defines how that gets marked. Whether `/sk:propose` stops for it (it doesn't) is `propose/SKILL.md`'s call, not this file's; this file only defines the mark itself, so it stays defined in exactly one place.

### The open-question marker

An unresolved point inside a `SHALL` sentence is marked inline with the literal token `[[OPEN:Q<n>]]`, where `<n>` is the question's number within the change (`Q1`, `Q2`, ...). Place it exactly where the undecided value would sit, inside the sentence itself, so the sentence reads as visibly broken rather than as a plausible, wrong claim:

```
- **THEN** the account SHALL lock after [[OPEN:Q2]] failed attempts
```

Not:

```
- **THEN** the account SHALL lock after a threshold of failed attempts to be determined
```

The second form still parses as a complete claim — weeks later, someone resolving it without re-reading the source can mistake it for a decision already made. The first form cannot be mistaken for anything but a gap: it fails to read as a sentence at all.

`[[OPEN:Q<n>]]` is a fixed literal, not a grammar. Do not vary the brackets, the prefix, or the spacing, and do not invent a second phrasing for the same purpose — a grader or a future tool matches it with a plain regex, and a second spelling defeats that.

### The two-step test

Run this per scenario, not per requirement — a requirement can hold both decided and undecided scenarios side by side.

**Step 1 — name the decidable token the `THEN` turns on.** A decidable token is exactly one of seven kinds. Walk every scenario through this list; treating it as a checklist turns a missed ambiguity from "didn't occur to me" into "skipped a line":

1. a number or threshold
2. a comparison operator or boundary (`<` vs `<=`, inclusive vs exclusive)
3. a sort key and its direction
4. a set boundary (`only`, `all`, `except`)
5. an actor or a permission
6. a user-facing display string
7. behaviour on empty, absent, or error input

Quote the exact source text — the description, the AC line, a comment — that pins this token to its value.

**Step 2 — try to write one other concrete value the same source text still permits.** If a second value fits without contradicting the quoted source, the token is unresolved. If the source rules out everything but one value, it's resolved — write that value in the sentence, no marker.

### The floor: no decidable token, no scenario

A `THEN` that names none of the seven kinds never reaches the two-step test — there is nothing in it to resolve. It is prose, per the rule already stated above: *"A scenario nobody could check is prose."* "The system SHALL handle large catalogs appropriately" does not get `[[OPEN:Q1]]` bolted onto it; it goes in Gaps, same as any criterion with no observable behaviour at all.

### Sorting a token: assumption or open question

For each unresolved token, decide which of two things it is:

- **An existing convention** — answerable by looking it up: a matching pattern already in `sk/specs/`, a value in `sk/config.yaml`, or the work item itself repeating the same choice elsewhere. Decide it yourself, write the concrete value, and record it under `## Assumptions` with the source. No marker.
- **A product decision** — a business threshold, a permission, user-facing wording — that no lookup answers. Write `[[OPEN:Q<n>]]` in the sentence and record `Q<n>` under `## Open questions`.

A Gap is a criterion the AC doesn't cover at all. An open question is a criterion the AC does cover, just not down to one value. Keep the two apart: they live in different sections of `proposal.md` and get resolved differently.

## Turning acceptance criteria into a spec

Acceptance criteria come off the board in whatever shape their author used. **Infer the mapping from that shape.** Do not apply a fixed rule such as "one criterion, one scenario" — real criteria do not obey it, and forcing them to either inflates the spec or collapses it.

The three shapes that actually occur:

**Grouped bullets** — a heading with a bullet list under it, repeated. The heading is the requirement; the bullets are its scenarios. This is the easiest case and needs no commentary in `proposal.md`.

**Given/When/Then sentences, ungrouped** — often one long run of sentences with no headings. Each sentence is already a scenario. Gather the ones that concern the same behaviour into a requirement and name it yourself.

**Prose** — one or more paragraphs describing how it should work. Split it by observable behaviour. Because that split is your judgement rather than the author's, **write down how you split it** in `proposal.md`, so a reviewer can disagree with the split itself instead of reverse-engineering it from the result.

Whatever the shape:

- A criterion you cannot turn into observable behaviour goes in **Gaps**, and you ask about it
- Never invent a scenario to round out a requirement. A spec that looks complete but says things nobody asked for is worse than one with an honest gap
- Criteria arrive as HTML. Strip tags and decode entities before anything else — see `azure-devops.md`

## Delta sections

A delta uses only these three headings:

```markdown
## ADDED Requirements
## MODIFIED Requirements
## REMOVED Requirements
```

Omit a section you are not using — do not leave it empty.

### `MODIFIED` restates the entire requirement

**A requirement under `## MODIFIED Requirements` must contain its full body: every scenario, including the ones this change does not touch.**

`/sk:archive` replaces the matching requirement in `sk/specs/` with what the delta holds. That is only safe because the delta restates everything. Write only the changed scenario and the rest is deleted — names still match, no conflict is reported, and the loss surfaces whenever someone later asks what that requirement actually covers.

The practical method: copy the requirement out of `sk/specs/<capability>/spec.md`, then edit the copy.

`/sk:archive` carries one net: if the merged requirement ends up with fewer scenarios than the one it replaces, it stops and asks. That net catches the common case, not every case — a delta that swaps one scenario for another keeps the count identical. Restating in full is the actual guarantee.

### `ADDED` and `REMOVED`

- `ADDED` — the requirement must not already exist in `sk/specs/`. If it does, that is a conflict for a person to resolve, not a merge
- `REMOVED` — name the requirement exactly and say in one line why it is going. No scenarios needed
