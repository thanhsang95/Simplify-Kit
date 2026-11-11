# Reading an Azure DevOps work item

Used by `/sk:propose` and `/sk:continue` (which re-fetches before writing a spec delta); the pull request and query sections near the end by `/sk:verify --pr` and `/sk:learn`. Azure DevOps is **read-only** throughout SimplifyKit: no comments, no new work items, no votes, no state changes, regardless of what is asked. Every rule in the work item sections exists because it already went wrong on this org's real data.

## Do not use `az boards` or `az devops invoke` to read work items

| Path | Replacement chars (U+FFFD) | Real em dashes |
|---|---|---|
| `az boards work-item show --expand all` | **9** | 0 |
| REST + access token | **0** | **9** |

`az` corrupts non-ASCII in what it writes — no `chcp 65001`, `PYTHONUTF8` or console encoding fixes it — and a pilot shipped four `?` into a final spec that way. `az devops invoke --area wit --resource comments` fails on every item (`can only concatenate str (not "NoneType") to str`). So reads go over REST; `az` only finds the default org and mints a token.

## Get the org and a token

```bash
az devops configure --list        # organization, project
az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 \
  --query accessToken -o tsv
```

The resource id is the constant Azure DevOps id, not a secret. **Never print the token** — keep it in a variable and the header only.

Use `ado.orgUrl` from `sk/config.yaml` **in full**: legacy orgs live at `https://<org>.visualstudio.com/`, and a rebuilt `https://dev.azure.com/<org>` URL fails for them.

## Fetch the work item

```
GET {orgUrl}/{project}/_apis/wit/workItems/{id}?$expand=all&api-version=7.1
Authorization: Bearer {token}
```

**`$expand=all` is required** — without it there is no `relations[]`, and a Task's intent lives on its parent.

| Field | Note |
|---|---|
| `System.WorkItemType` | `User Story` / `Bug` / `Task` / `Feature` — decides whether to cascade |
| `System.Title`, `System.State` | |
| `System.Description` | **strip HTML** |
| `Microsoft.VSTS.Common.AcceptanceCriteria` | **strip HTML**. Often the key is missing entirely — that is Branch B, not an error |
| `Microsoft.VSTS.TCM.ReproSteps` | Bugs only. **strip HTML**. Where a Bug's expected behaviour usually is |
| `System.AreaPath`, `System.IterationPath`, `System.Tags` | context only |

`relations[]` gives `rel` plus the id at the end of `url`. `Tested By` is read on every item; a `Task`'s parent always; `Related` and a non-Task's parent only when Branch B fires (sections below).

## Fetch the comments

```
GET {orgUrl}/{project}/_apis/wit/workItems/{id}/comments?api-version=7.1-preview.4
```

Take `comments[].text` (strip HTML), author and date. Comments are where scope gets cut after the description was written. Where one contradicts the description **or the acceptance criteria**, **the comment wins**, and `proposal.md` records which comment overrode what.

## Stripping HTML

Read the tag structure first — `<strong>heading</strong>` followed by `<ul><li>` is a requirement with its scenarios — then replace tags (`<[^>]+>`) with a space and decode entities (`&quot;` `&amp;` `&lt;` `&gt;` `&nbsp;` `&mdash;`). **No HTML tag may survive into a spec file.**

## Check for corrupted characters before writing anything

After stripping, scan for **U+FFFD**. If present, **stop and do not write the spec**: report the field and that the fetch path corrupted the source. This is what catches someone reintroducing `az boards` because it looks simpler.

## Tasks inherit intent from their parent

A `Task` usually holds an implementation checklist; the criteria live above it. When `System.WorkItemType == "Task"`:

1. Take the `relations[]` entry with `rel == "System.LinkTypes.Hierarchy-Reverse"` — the parent
2. Fetch it the same way, and take its full fields, its comments and its `Tested By` test cases
3. Parent also a Task? Go up one more. **Stop at two levels**

Name both the Task and its parent in `proposal.md`. A Task under a `Bug` is handled as a Bug.

## A Bug's acceptance criteria are its expected result

A `Bug` rarely has an acceptance criteria field; its `ReproSteps` hold the steps, **expected result** and **actual result**. Its criteria are, in order:

1. `Microsoft.VSTS.Common.AcceptanceCriteria`, when present and usable
2. Otherwise the expected result in the repro steps — steps as `GIVEN`/`WHEN`, expected result as `THEN`. Board content, so `AC source: work item`

The **actual result** is the symptom, not a criterion: what `/sk:apply`'s first test must reproduce (`tdd.md`), recorded in one line in `proposal.md`.

**Repro steps with no expected result are Branch B.** "It should not crash" is your reading; an empty message, a fallback, an error or blocking the input all qualify. Ask, recommending one — a linked test case may already answer it. Comments still win.

**A Bug that restores behaviour `sk/specs/` already specifies needs no change**: the fix is a commit or PR with `AB#<id>` and a regression test from that scenario (`propose/SKILL.md` covers the asking).

## Test cases linked to the item

A `Test Case` linked by `Tested By` is the board saying "this checks that item" — QA often writes the exact message or boundary there. Not a relevance guess, so it is read on every item, every branch, every type (a Task's via its parent).

1. Take `relations[]` entries with `rel == "Microsoft.VSTS.Common.TestedBy-Forward"`, at most the first **10**; say how many went unread
2. Fetch each like the primary item (`$expand=all`, U+FFFD check). No comments, and **no further `relations[]`** except shared steps
3. Read `System.Title` and `Microsoft.VSTS.TCM.Steps`, which is XML:

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

   Each `<step>` holds the **action**, then the **expected result** (empty on an `ActionStep`). **Decode twice**: XML entities (`&lt;DIV&gt;` → `<DIV>`), strip tags, then HTML entities (`&quot;` → `"`)
4. `<compref ref="<id>">` inlines a **Shared Steps** item: fetch it once, read its Steps the same way, in place. They do not nest
5. `@name` is a parameter; its values in `Microsoft.VSTS.TCM.LocalDataSource` are examples of the same behaviour

Test plans, suites, runs and outcomes are not read: a result says what the code does, not what it should do.

**A test case is evidence, not acceptance criteria** — written by whoever tests, sometimes before the criteria last changed. Never a scenario on your own:

- **Branch A** — compare each expected result with the criteria. Covered → nothing. Not covered or contradicting → a question (in scope? which side is right?) and a Gap until answered. The exact value of a token the criteria leave open → `pins <what>`, which `/sk:continue` resolves from, quoted under `## Assumptions`
- **Branch B** — expected results that look like the answer are quoted and offered for confirmation; confirmed → `AC source: test cases AB#<id>[, AB#<id>], confirmed`

Record each under `## Test cases`: id, title, every step quoted as decoded, `"<action>" → "<expected result>"`, labelled `covered`, `pins <what>`, `open` or `confirmed as criterion`. Quote, never paraphrase — it is the only copy `/sk:continue` and `/sk:apply` read.

## A related item can already answer a Branch B gap

Only once Branch B has fired — with usable AC of its own, a related item would only mix in behaviour nobody asked for here.

1. `relations[]` entries with `rel == "System.LinkTypes.Related"`, at most the first **3**
2. Fetch each like the primary item. **One hop**: never follow its own `relations[]`
3. Never descend `System.LinkTypes.Hierarchy-Forward` (children). A Story's children are Tasks with no criteria; a `Feature`'s Story children do carry criteria, but reading them is a known, unclosed gap — not something this rule covers
4. Looks like it answers the gap → **not confirmation**. Name it and quote it when asking: "do AB#\<id\>'s criteria apply here?"
5. Does not bear on the gap → do not manufacture a confirmation question from it; ask the plain "what are the acceptance criteria?" (noting it was checked is fine)
6. Record it under Gaps as a pending confirmation as soon as it is read, so a reviewer sees it
7. Confirmed → continue as Branch A, and move the entry from Gaps to a note naming the source

## A parent can narrow a Branch B gap when the item is not a Task

Only once Branch B has fired **and** the item is not a `Task` (a Task's parent was already read).

1. The `rel == "System.LinkTypes.Hierarchy-Reverse"` entry — at most one
2. Fetch it like the primary item, comments included. **One hop**: no grandparent, no further relations
3. Parent also empty or thin → nothing to surface; ask the plain question

**Never offer a parent's criteria wholesale.** A `Feature` describes everything under it; lifting its AC into one Story overstates what that Story covers — fabrication from above. Ask a **narrowing** question instead: "the parent Feature is about migrating reporting to the new backend; does this story cover part of that, and which part should be verified?" The answer becomes the criteria, not the Feature's text.

A related item and a parent both usable → one question naming both. Record the parent under Gaps as pending, then as a note with what the user confirmed.

## Pull requests (read-only)

Same token, same `ado.orgUrl` in full, same U+FFFD check on every text field, and **never print the token**. Not `az repos pr show`: it goes through the same `az` output path that corrupts non-ASCII. These endpoints come from the REST reference (api-version 7.1); unlike the work item sections, they have not yet been run against this org's data.

**One PR by id**

```
GET {orgUrl}/{project}/_apis/git/pullrequests/{id}?api-version=7.1
```

| Field | Note |
|---|---|
| `repository.id` | needed for the threads call |
| `sourceRefName`, `targetRefName` | `refs/heads/<branch>` — drop the prefix for `git` commands |
| `title`, `description` | Markdown, not HTML; may carry `AB#<id>` |
| `lastMergeSourceCommit.commitId` | the source commit the PR currently points at |
| `status`, `closedDate` | `active` / `completed` / `abandoned`; `closedDate` only once closed |

**A PR's threads**

```
GET {orgUrl}/{project}/_apis/git/repositories/{repositoryId}/pullRequests/{id}/threads?api-version=7.1
```

`value[]` is the threads. Per thread: `status` — `active`, `fixed`, `wontFix`, `closed`, `byDesign`, `pending` (absent or `unknown` on Azure DevOps' own system threads); `isDeleted` → skip; `comments[]` with `content` (Markdown), `author.displayName`, `publishedDate`, and `commentType` — `system` comments are Azure DevOps' own (votes, pushes), not a person's. A `/sk:verify` report is a comment whose `content` starts with `## Verification report:`; the latest by `publishedDate` is the previous round.

**Completed PRs in a period**

```
GET {orgUrl}/{project}/_apis/git/pullrequests?searchCriteria.status=completed&searchCriteria.minTime=<ISO 8601>&searchCriteria.queryTimeRangeType=closed&$top=100&$skip=0&api-version=7.1
```

Without `status` the default is active PRs only; without `queryTimeRangeType=closed`, `minTime` filters by creation date. Page by raising `$skip` by `$top` until a page returns fewer than `$top` items.

## Work item queries (read-only)

```
POST {orgUrl}/{project}/_apis/wit/wiql?api-version=7.1
Content-Type: application/json

{"query": "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = 'Bug' AND [System.Tags] CONTAINS 'escaped' AND [System.ChangedDate] >= '<YYYY-MM-DD>'"}
```

**This POST only reads** — WIQL takes its query as a body. It is the only POST in SimplifyKit: never any other POST, nor PATCH, PUT or DELETE, on any endpoint. The response holds `workItems[].id` only; fetch each item as `## Fetch the work item` does (strip HTML, U+FFFD check).

## When a fetch fails

Not signed in, wrong org, no permission, missing item — report the actual error and ask the user to paste the contents. **Never invent work item content**: a fabricated criterion is indistinguishable from a real one once it is in a spec.
