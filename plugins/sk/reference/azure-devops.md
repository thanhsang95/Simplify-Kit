# Reading an Azure DevOps work item

Used by `/sk:propose`. Azure DevOps is **read-only** throughout SimplifyKit: no comments, no new work items, no state changes, regardless of what is asked.

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
| `Microsoft.VSTS.TCM.ReproSteps` | Bugs only. **strip HTML** |
| `System.AreaPath`, `System.IterationPath`, `System.Tags` | context only |

And `relations[]` — `rel` (Parent / Child / Related / AttachedFile) plus the id at the end of `url`. `Parent` is read unconditionally when the item is a `Task` (below). `Related` is read conditionally, only when Branch B fires — see "A related item can already answer a Branch B gap" below.

## Fetch the comments

```
GET {orgUrl}/{project}/_apis/wit/workItems/{id}/comments?api-version=7.1-preview.4
Authorization: Bearer {token}
```

Take `comments[].text` (strip HTML), author, and date.

**Read these.** Comments are where scope gets cut after the description was written — "we agreed to skip X", "do this instead of that". Where a comment contradicts the description, **the comment wins**, and `proposal.md` records which comment overrode what. A spec built from the description alone can specify work the team already decided not to do.

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
3. Take the parent's full fields — description, acceptance criteria, repro steps
4. Read the parent's comments too; scope-defining discussion usually happens there
5. Parent is also a Task? Go up one more. **Stop at two levels.**

In `proposal.md`, name both: the Task and the parent it inherited from.

## A related item can already answer a Branch B gap

`relations[]` is fetched on every read (`$expand=all` again ensures this), but
until this section existed nothing consumed the `System.LinkTypes.Related`
entries in it — a User Story could arrive with thin or absent acceptance
criteria while a `Related` item on the same board already specified the exact
behaviour, and `/sk:propose` had no way to notice.

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
3. Ignore `System.LinkTypes.Hierarchy-Forward` (children) for this purpose. A
   child is typically a `Task`, which per the section above carries an
   implementation checklist and no acceptance criteria of its own —
   descending into it does not fill the gap
4. If a related item's description or acceptance criteria look like they
   answer the current item's gap, **do not treat that as confirmation.** Name
   the item and quote or paraphrase what it says when Branch B asks the user,
   so the question becomes "does AB#\<id\>'s criteria apply here?" instead of a
   bare "what are the acceptance criteria?" A plausible-looking related item
   is not the same thing as the user's answer
5. If the user confirms, continue as Branch A using the confirmed content, and
   record in `proposal.md` which related item the criteria came from — the
   same way a Task names the parent it inherited from

## When a fetch fails

Not signed in, wrong organisation, no permission, item does not exist — report the actual error and ask the user to paste the work item contents.

**Never invent work item content.** A fabricated acceptance criterion is indistinguishable from a real one once it is in a spec file.
