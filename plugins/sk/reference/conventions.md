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
