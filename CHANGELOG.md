# Changelog

## 0.1.1 — unreleased

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

- [x] **`propose-related-item-is-noise/fixture.sh` reviewed** when it was added. Work items 21000 and 21001 and their expiry-filter/dark-mode stories are invented; org and project match the invented names already used elsewhere. No personal names, emails, customer names or contract identifiers.
