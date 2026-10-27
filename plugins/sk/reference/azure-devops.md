# Reading an Azure DevOps work item

Used by `/sk:propose` and `/sk:continue` (which re-fetches the work item before writing a spec delta). Azure DevOps is **read-only** throughout SimplifyKit: no comments, no new work items, no state changes, regardless of what is asked.

Every rule here exists because it has already gone wrong on this org's real data. None of it is optional polish.

## Do not use `az boards` or `az devops invoke` to read work items

Both were tried against this org and both failed, measurably:

| Path | Replacement chars (U+FFFD) | Real em dashes |
|---|---|---|
| `az boards work-item show --expand all` | **9** | 0 |
| REST + access token | **0** | **9** |

`az` corrupts non-ASCII characters on the way out — an em dash in an acceptance criterion arrives as `?`. Setting `chcp 65001`, `PYTHONIOENCODING=utf-8`, `PYTHONUTF8=1`, and even `[Console]::OutputEncoding` does **not** fix it: the damage is already in what `az` writes, not in how the shell reads it. A spec generated from that text carries the damage permanently, and a pilot on this repo did exactly that — four `?` characters reached the final spec file.

`az devops invoke --area wit --resource comments` fails outright with an extension-internal error, reproducible on every work item:

```
ERROR: can only concatenate str (not "NoneType") to str
  .../azext_devops/dev/common/exception_handler.py
```

So both reads go over REST instead. `az` is still used for two things it does correctly: discovering the default org, and minting a token.

## Get the org and a token

```bash
az devops configure --list        # organization, project — already set on this machine
az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 \
  --query accessToken -o tsv
```

`499b84ac-1321-427f-aa17-267ca6975798` is the Azure DevOps resource id; it is constant, not a secret.

**Never print the token.** Keep it in a variable, pass it in the header, and do not echo it into output, logs or artifacts.

Take the org URL from `sk/config.yaml` → `ado.orgUrl` and pass it **in full**. Legacy organisations still live at `https://<org>.visualstudio.com/`, and `https://dev.azure.com/<org>` is a different endpoint for them. Reconstructing the URL is how a lookup fails against an org that exists.

## Fetch the work item

```
GET {orgUrl}/{project}/_apis/wit/workItems/{id}?$expand=all&api-version=7.1
Authorization: Bearer {token}
```

**`$expand=all` is required.** Without it the response has no `relations[]` — no parent, no children, no attachments — and a Task's real intent lives on its parent.

Take from `fields`:

| Field | Note |
|---|---|
| `System.WorkItemType` | `User Story` / `Bug` / `Task` / `Feature` — decides whether to cascade |
| `System.Title`, `System.State` | |
| `System.Description` | **strip HTML** |
| `Microsoft.VSTS.Common.AcceptanceCriteria` | **strip HTML**. Often absent entirely — the key is missing, not empty. That is Branch B, not an error |
| `Microsoft.VSTS.TCM.ReproSteps` | Bugs only. **strip HTML**. Where a Bug's expected behaviour usually lives — see "A Bug's acceptance criteria are its expected result" below |
| `System.AreaPath`, `System.IterationPath`, `System.Tags` | context only |

And `relations[]` — `rel` (Parent / Child / Related / Tested By / AttachedFile) plus the id at the end of `url`. `Parent` is read unconditionally when the item is a `Task` (below). For every other type, `Parent` (`Hierarchy-Reverse`) is read conditionally, only when Branch B fires — see "A parent can narrow a Branch B gap when the item is not a Task" below. `Related` is read conditionally too, only when Branch B fires — see "A related item can already answer a Branch B gap" below. `Tested By` is read on every item, whatever the branch — see "Test cases linked to the item" below.

## Fetch the comments

```
GET {orgUrl}/{project}/_apis/wit/workItems/{id}/comments?api-version=7.1-preview.4
Authorization: Bearer {token}
```

Take `comments[].text` (strip HTML), author, and date.

**Read these.** Comments are where scope gets cut after the description was written — "we agreed to skip X", "do this instead of that". Where a comment contradicts the description **or the acceptance criteria**, **the comment wins**, and `proposal.md` records which comment overrode what. A spec built from the description or AC alone can specify work the team already decided not to do — or leave an acceptance criterion looking undecided when a comment already settled it.

## Stripping HTML

Acceptance criteria are rich text: `<ol><li>`, `<ul><li>`, `<div><span>`, `<p dir=ltr><strong>` — whatever the author's editor produced.

Replace tags (`<[^>]+>`) with a space and decode entities (`&quot;` `&amp;` `&lt;` `&gt;` `&nbsp;` `&mdash;`) **before** reading the criteria for meaning.

Two consequences worth knowing before you plan the mapping:

- The tag structure carries the author's grouping. `<strong>heading</strong>` followed by `<ul><li>` is a requirement with its scenarios — read the structure first, then strip
- **No HTML tag may survive into a spec file.** A `<li>` in `sk/specs/` means the stripping step was skipped

## Check for corrupted characters before writing anything

After stripping, scan the text for the replacement character **U+FFFD** (`?`).

If you find one, **stop. Do not write the spec.** Report which field it appeared in and that the fetch path corrupted the source text. A spec is a contract; one that silently contains `?` where the author wrote an em dash is a contract nobody agreed to, and it is far harder to spot later than to catch here.

This check is what catches a regression in the fetch path — including someone reintroducing `az boards work-item show` because it looks simpler.

## Tasks inherit intent from their parent

A `Task` usually carries an implementation checklist and nothing else. The acceptance criteria live on the `User Story` or `Bug` above it.

When `System.WorkItemType == "Task"`:

1. Find the `relations[]` entry with `rel == "System.LinkTypes.Hierarchy-Reverse"` — that is the parent
2. Fetch the parent the same way, `$expand=all` included
3. Take the parent's full fields — description, acceptance criteria, repro steps — and the parent's `Tested By` test cases, read as "Test cases linked to the item" below says
4. Read the parent's comments too; scope-defining discussion usually happens there
5. Parent is also a Task? Go up one more. **Stop at two levels.**

In `proposal.md`, name both: the Task and the parent it inherited from. A Task whose parent is a `Bug` is handled as a Bug from here on — the next section applies to the parent's fields.

## A Bug's acceptance criteria are its expected result

A `Bug` rarely carries `Microsoft.VSTS.Common.AcceptanceCriteria` (only some processes give it the field at all). What it carries is `Microsoft.VSTS.TCM.ReproSteps`: the steps, the **expected result** and the **actual result**, in whatever shape the reporter typed. Before this was read, every Bug arrived at Branch B as "no acceptance criteria" and the user was asked for what the board already held.

For a `Bug`, the acceptance criteria are, in order:

1. `Microsoft.VSTS.Common.AcceptanceCriteria`, when present and usable — exactly as for any other item
2. Otherwise the expected result stated in the repro steps. The steps become the `GIVEN`/`WHEN`, the expected result the `THEN`. This is board content, so it is `AC source: work item`, not a reading of your own

The **actual result** is not a criterion. It is the symptom: what `/sk:apply`'s first test must reproduce before anything is fixed (`tdd.md`). `/sk:apply` never reads Azure DevOps, so `proposal.md` records it in one line.

**Repro steps with no expected result are Branch B.** "It should obviously not crash" is a reading of your own, and a Bug whose correct behaviour nobody wrote down is exactly where the expected result is a product decision — an empty message, a fallback value, an error, or blocking the input are all "not crashing". Ask, recommending one; a linked test case's expected result (below) may already answer it. Comments still win over the repro steps, the same as over a description.

**A Bug that restores behaviour `sk/specs/` already specifies needs no change.** When a scenario in `sk/specs/` (or an unarchived delta) already states the expected result, the code drifted from the spec and the spec is still right: the fix is a commit or PR with `AB#<id>`, its regression test written from that scenario. A change there would have nothing for its spec delta to say, and `/sk:continue` has no way to finish a change without one. `SKILL.md` covers how `/sk:propose` asks about it.

## Test cases linked to the item

A `Test Case` linked by `Tested By` is the board saying, explicitly, "this checks that item". QA often writes the precise expected results there — the exact message, the boundary value — while the acceptance criteria stay a sentence. Unlike `Related` and `Parent`, it is **not** a guess about relevance, so it is read on every item, in every branch, for every type — `User Story`, `Bug`, `Feature`, and a `Task`'s parent.

1. Look at `relations[]` for entries where `rel == "Microsoft.VSTS.Common.TestedBy-Forward"`. Take at most the first **10**, and say in `proposal.md` how many were left unread when there are more
2. Fetch each the same way as the primary item — `$expand=all`, checked for U+FFFD. Do not read its comments, and **do not follow its own `relations[]`** except for shared steps (point 4)
3. Read `System.Title` and `Microsoft.VSTS.TCM.Steps`. Steps is XML, not HTML:

   ```xml
   <steps id="0" last="3">
     <step id="2" type="ValidateStep">
       <parameterizedString isformatted="true">&lt;DIV&gt;&lt;P&gt;Open the download page&lt;/P&gt;&lt;/DIV&gt;</parameterizedString>
       <parameterizedString isformatted="true">&lt;DIV&gt;&lt;P&gt;The &amp;quot;Export&amp;quot; button is disabled&lt;/P&gt;&lt;/DIV&gt;</parameterizedString>
       <description/>
     </step>
     <compref id="3" ref="20950" />
   </steps>
   ```

   Each `<step>` holds two `parameterizedString`s: the **action**, then the **expected result** (empty on an `ActionStep`). Their text is HTML escaped *inside* XML, so decode twice: XML entities first (`&lt;DIV&gt;` → `<DIV>`), then strip the tags, then decode the HTML entities that remain (`&quot;` → `"`). Decoding once leaves `&quot;` in the text; skipping the strip leaves `<DIV>` — the same failure as a `<li>` in a spec
4. A `<compref ref="<id>">` pulls in a **Shared Steps** work item at that point. Fetch it once and read its `Microsoft.VSTS.TCM.Steps` the same way, in place. Shared steps do not nest further
5. `@name` in a step is a parameter. Its values live in `Microsoft.VSTS.TCM.LocalDataSource`; read them as examples of the same behaviour, not as separate test cases

Not read: test plans, test suites, test runs and outcomes. A run's pass or fail says what the code does, not what it should do, and the Test Plans API is a different surface for nothing the spec needs.

**A test case is evidence, not acceptance criteria.** It was written by whoever tests the item, sometimes long before the criteria last changed, and its steps describe clicks rather than contracts. Never put a scenario in a spec from a test case on your own. What it is used for depends on the branch:

- **Usable AC (Branch A)** — compare each expected result with the criteria. One the criteria already cover needs nothing. One they do not cover, or one that contradicts them, is a question for the user (`SKILL.md` Step 4) — whether it is in scope, and which side is right. Until someone answers it is a Gap, never a scenario. When it is the more precise value of a token the criteria leave open ("an error message" in the AC, the exact message in the test case), it is labelled `pins <what>` and is the source `/sk:continue` resolves that token from, quoted under `## Assumptions`
- **AC missing (Branch B)** — expected results that look like they answer the gap are named and quoted when Branch B asks, the same way as a `Related` item: a question to confirm, never settled fact. When the user confirms, `AC source` is `test cases AB#<id>[, AB#<id>], confirmed`

Record every test case read in `proposal.md` under `## Test cases` — id, title, and every step quoted as decoded, `"<action>" → "<expected result>"`, labelled `covered`, `pins <what>`, `open` or `confirmed as criterion`. Quote, never paraphrase: that record is the only copy `/sk:continue` (the `WHEN`, the `THEN`, a pinned value) and `/sk:apply` (test setup) read; neither re-fetches a test case.

## A related item can already answer a Branch B gap

`relations[]` is fetched on every read (`$expand=all` again ensures this). A
User Story can arrive with thin or absent acceptance criteria while a
`Related` item on the same board already specifies the exact behaviour —
this is where that gets read.

This only fires when `/sk:propose` has already landed in Branch B
(`SKILL.md` — AC missing or unusable). A work item with usable AC of its own
does not need this: reading a Related item there would risk mixing in
behaviour the current item's own AC never asked for, which is exactly what
the no-fabrication guardrail exists to prevent.

When Branch B fires:

1. Look at `relations[]` for entries where `rel == "System.LinkTypes.Related"`.
   Take at most the first **3** — a busy board can carry many, and reading all
   of them turns one fetch into an open-ended crawl
2. Fetch each the same way as the primary item — `$expand=all`, HTML
   stripped, checked for U+FFFD. **Do not follow that item's own
   `relations[]`.** One hop only, the same shape of bound the Task cascade
   above already uses and for the same reason: unbounded traversal on a busy
   board does not stay small
3. Ignore `System.LinkTypes.Hierarchy-Forward` (children) for this purpose,
   whatever the current item's type. When the current item is a `User Story`
   or `Bug`, its children are typically `Task`s, which per the section above
   carry an implementation checklist and no acceptance criteria of their own
   — descending would not fill the gap even if this rule allowed it.

   That reasoning does not hold when the current item is a `Feature`: its
   children are usually `User Story` items, which do carry acceptance
   criteria of their own, and a `Feature` is a reachable input here (see the
   type table above). This rule still does not follow them — `Related` is
   the only traversal this fix adds, bounded the way point 1 and 2 describe.
   A `Feature` with thin AC of its own and no `Related` item that answers the
   gap falls through to asking the user directly, same as every Branch B case
   did before this fix landed. Following `Hierarchy-Forward` for a `Feature`
   is a known gap this rule does not close, not a case this rule's reasoning
   covers
4. If a related item's description or acceptance criteria look like they
   answer the current item's gap, **do not treat that as confirmation.** Name
   the item and quote or paraphrase what it says when Branch B asks the user,
   so the question becomes "does AB#\<id\>'s criteria apply here?" instead of a
   bare "what are the acceptance criteria?" A plausible-looking related item
   is not the same thing as the user's answer
5. If a related item's content does **not** look like it answers the gap — it
   concerns a different surface, is a stray bug report, or is linked `Related`
   without actually bearing on this item's behaviour — do not manufacture a
   confirmation question out of it anyway. Ask the same bare "what are the
   acceptance criteria?" question Branch B always asks when no related item
   helps. Noting that a related item was checked and found unrelated is fine;
   presenting its unrelated content as something the user might confirm is
   not — that misleads rather than helps, which is exactly what point 4
   exists to prevent
6. Record it in `proposal.md`'s Gaps section as soon as it is read — name the
   item and mark the confirmation as pending — even before the user answers.
   That is what makes the read visible to a reviewer instead of a fact only
   the chat transcript holds
7. If the user confirms, continue as Branch A using the confirmed content, and
   move that entry from Gaps to a note recording which related item the
   criteria came from — the same way a Task names the parent it inherited from

## A parent can narrow a Branch B gap when the item is not a Task

The Task→parent cascade above only fires when `System.WorkItemType ==
"Task"`. Everything else — `User Story`, `Bug`, `Feature` — reaches Branch B
with its own `relations[]` still unread for `Hierarchy-Reverse`, even though
a parent is exactly the kind of connected item the `Related` rule above
already reads for the same gap. A `User Story` whose own AC is empty can sit
directly under a `Feature` that already describes what the effort is about;
asking a blank "what are the acceptance criteria?" ignores content one hop
away, the same failure the `Related` rule exists to close.

This only fires when Branch B has fired (`SKILL.md` — AC missing or
unusable) **and** the current item is not a `Task` — a Task's parent was
already read unconditionally in the fetch step above, with its fields taken
directly, and this rule does not re-run on top of that.

When both conditions hold:

1. Look at `relations[]` for the entry where `rel ==
   "System.LinkTypes.Hierarchy-Reverse"`. There is at most one parent
2. Fetch it the same way as the primary item — `$expand=all`, HTML stripped,
   checked for U+FFFD — and read its comments too; scope-defining discussion
   usually happens there, the same reason the Task cascade reads parent
   comments
3. **One hop only.** Do not follow the parent's own `relations[]`, and do not
   go up again if the parent's content also turns out to be thin. A second
   hop trades an already-loose signal (a grandparent's scope is broader
   still) for more crawl, in the wrong direction from the tightening this
   rule is trying to do
4. If the parent's own description and acceptance criteria are also empty or
   too thin to say anything, there is nothing to surface. Fall through to the
   plain "what are the acceptance criteria?" ask — noting the parent was
   checked, if that is useful context, the same as a checked-and-unrelated
   `Related` item

**Do not treat a usable parent the way a usable `Related` item is treated.**
A `Related` item is typically the same shape as the current one — another
`User Story`, describing a comparable slice of behaviour — so confirming its
content as this item's own AC is a reasonable question to ask. A parent one
level up is structurally broader: a `Feature` describes the scope of
everything under it, and a `User Story` is one slice of that scope. Asking
"does the parent's acceptance criteria apply here?" invites a wholesale
"yes," and lifting a `Feature`'s AC wholesale into one `User Story` overstates
what that one story covers — the fabrication risk this whole workflow exists
to avoid, just arriving from above instead of sideways.

Ask a narrowing question instead: name the parent, say what it is about, and
ask what part of that scope the current item covers. For example, a `User
Story` with an empty AC field, sitting under a `Feature` about migrating a
reporting pipeline to a new backend, is not "does the Feature's AC apply
here" — it is "the parent Feature is about migrating reporting to the new
backend; does this story cover part of that, and if so, which part should be
verified?" The user's answer becomes the acceptance criteria to write, not
the Feature's text verbatim.

If both a `Related` item and a parent surface usable content in the same
pass, combine them into one question naming both sources rather than asking
twice.

Record the parent in `proposal.md`'s Gaps section as soon as it is read,
marked as a pending confirmation, the same as a `Related` item — and once the
user answers, move that entry to a note recording that the parent supplied
the context, together with what the user actually confirmed.

A `Feature`'s own children (`Hierarchy-Forward`) are a separate, still-open
gap: a `Feature` input's `User Story` children typically carry real AC of
their own, but nothing here reads them. This rule does not close that — it
only adds `Hierarchy-Reverse` (parent), the opposite direction of traversal.

## When a fetch fails

Not signed in, wrong organisation, no permission, item does not exist — report the actual error and ask the user to paste the work item contents.

**Never invent work item content.** A fabricated acceptance criterion is indistinguishable from a real one once it is in a spec file.
