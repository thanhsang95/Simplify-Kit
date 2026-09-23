# Eval suite

Eight cases. Each has exactly one grader on **how it got there** — a `tool_used: Skill` check — plus one or more graders on the **result**, so a run tells you both whether the output was right and whether SimplifyKit is what produced it.

## Running it

```bash
# from plugins/sk
claude plugin eval . --allow-tools Write Edit --scaffold --no-publish
```

### On Windows, put Git Bash ahead of WSL on PATH

`scaffold_script` is a Bash script and seven of eight cases need one — every case except `ignores-unrelated-request`, which touches no filesystem. The `bash` on a default Windows PATH is `C:\Windows\System32\bash.exe` (WSL), which fails with `execvpe(/bin/bash) failed: No such file or directory` unless a distro is installed. Every scaffolded case then scores 0 with `scaffold failed (exit 1)`.

```powershell
$env:PATH = "C:\Program Files\Git\bin;" + $env:PATH
```

With Git Bash first, scaffolds run normally. This is environment setup, not a plugin bug — but it looks exactly like a broken suite if you do not know.

## Gating

`--threshold` is a global flag with no per-case equivalent, and the cases carry different numbers of scored graders, so gating is three commands filtered by tag:

| Tag | Cases | Scored graders | Threshold |
|---|---|---|---|
| `wi` | `propose-from-work-item` | 7 | 0.95 |
| `init` | `init-sets-up-sk` | 3 | 0.85 |
| `core` | the other six: `apply-implements-tasks`, `archive-merges-spec`, `archive-rejects-scenario-loss`, `propose-missing-ac-asks`, `ignores-unrelated-request`, `propose-does-not-auto-apply` | 2–3 each | 0.8 |

`wi` sits at 0.95 deliberately. At 0.85 a grader that fails in **all three runs** still scores 6/7 = 0.857 and the case stays green — which would let the faithfulness and HTML-stripping graders die unnoticed.

## Things that are easy to get wrong here

- **`regex` targets one literal file.** Only `file_exists` takes a glob. That is why every prompt pins the change id and capability
- **Regex is JavaScript without multiline.** `^` matches the start of the whole string, not of a line. Use `flags: m`, or drop the anchor
- **`file_exists` counts files created during the run.** Anything the scaffold made, or the model only edited, is invisible to it
- **`tool_used` counts calls that MATCH `input_match`.** A pattern broken so it matches nothing passes a `min: 0, max: 0` check. The write-path pattern in `propose-from-work-item` and `propose-does-not-auto-apply` (both `min: 0, max: 0`) is therefore repeated verbatim in `apply-implements-tasks` with `min: 1`, where the run is supposed to write outside `sk/`. **Change one, change all three**
- **`arm: both` only does something on a `tool_used: Skill` grader.** Elsewhere it is a no-op
- **Runs have no Bash.** No `az`, no deletes, no moves. Those paths are verified by hand, not here
- **`--tag` and `--case` resolve `name`/`tags` from `case.yaml` *or* `prompt.md`'s frontmatter, not just `case.yaml`.** A case with no `case.yaml` can still be gated if `prompt.md` declares them itself — and a case that declares both risks the two drifting apart. This suite's convention is `case.yaml` as the single source of truth for `name`/`tags`; `prompt.md`'s frontmatter carries only `max_turns`, `timeout_seconds` and `allowed_tools`

## Fixtures

`work-item-*.json` keep the HTML shape real Azure DevOps criteria arrive in — `<ol><li>`, `&quot;`, `&mdash;`, one long flat list — because that shape is what the skill has to cope with. Product and customer names are replaced; no person, email or contract identifier appears in any of them.

**Re-check this before the repository gets a remote.** See the pre-push checklist in `CHANGELOG.md`.

## What this suite cannot tell you

Each run loads only this plugin, so Claude sees four skills with full descriptions. In a real repository it may see ninety-five, truncated. Whether `sk:propose` wins that competition is not measurable here and is checked by hand in the host repo.

Each case is also one initial user message; the agent then runs on its own — tool calls, not further user turns — until it stops, asks a question, or hits `max_turns`/`timeout_seconds`. Nothing here can script a second user message. That rules out a *real* propose → apply handoff, where propose's actual output (not a fixture standing in for it) becomes apply's actual input in a later turn. `propose-does-not-auto-apply` tests the adjacent thing this runner **can** see in one turn: a request spanning both skills' territory still produces only one of them, because `propose`'s own guardrail refuses to chain into `apply` without a new request. It proves the boundary holds; it does not prove a real handoff works once the user gives that new request.

That case is also the expensive one: a default run (6 runs, with-without) costs **$2.68**, ~$0.45/run and 552s total — roughly 17× `archive-rejects-scenario-loss` ($0.16). The `max_turns: 40` budget exists so a run that starts sliding into implementation has enough room to actually do it, which is the point, but it means anyone wiring this into CI is paying agentic-implementation prices for what looks like a planning-only case.
