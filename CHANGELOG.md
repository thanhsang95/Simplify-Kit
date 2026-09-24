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

- [x] **`propose-parent-narrows-gap/fixture.sh` reviewed** when it was added. Work items 21200, 21201 and 21202 and their catalog-sync-migration story are invented; org and project match the invented names already used elsewhere. No personal names, emails, customer names or contract identifiers.
