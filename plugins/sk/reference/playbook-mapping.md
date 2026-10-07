# How SimplifyKit maps to the AI-native SDLC playbook

SimplifyKit follows [the AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook): every stage commits an artifact the next stage can read, and together those artifacts are the audit trail.

| Stage | Playbook | SimplifyKit, round 1 |
|---|---|---|
| 1. Plan | Intent captured once, in the originator's words, as a versioned artifact | **Already done, on the board.** The Azure DevOps work item *is* the intent artifact. `/sk:propose` reads it; it does not ask anyone to write it again. `proposal.md` is a pointer plus what the board does not hold — how the criteria were read, what was assumed, what is still open. Work with no work item enters as a direct request, given explicitly to `/sk:propose`; then `proposal.md` holds the request verbatim and *is* the intent artifact |
| 2. Design | Requirements and design in one session; policy applied while the spec is written | `/sk:propose` records how the criteria were read in `proposal.md`; `/sk:continue` then writes `specs/<capability>/spec.md` as a delta, and `design.md` when there is a real trade-off, one artifact per invocation. Project policy arrives through `sk/config.yaml` → `rules`, applied while writing rather than reviewed afterwards |
| 3. Build | Nothing implemented without an accepted plan; institutional knowledge becomes files the agent reads | `/sk:apply` works `tasks.md` and refuses to start without it. Institutional knowledge is `sk/config.yaml` → `context`, which points at the repo's own docs instead of copying them |
| 4. Test | Every session checks its own work; the configuration that steers the agent is regression-tested | `/sk:verify` checks the implementation against the change's own artifacts — every task done, every requirement and scenario backed by code and tests, nothing built that no requirement asked for, `design.md` and `sk/config.yaml` → `rules` followed — and runs the repo's test command when it has a shell. It reports and fixes nothing. The **plugin's** configuration is regression-tested by `evals/` — that is the playbook's "configuration gets tested" applied to this kit itself |
| 5. Deploy | Review runs in both directions; governance enforced as the agent acts | Review is human, through the diff and the artifacts. `/sk:verify`'s report is input to that review, not a replacement or a gate: `/sk:archive` does not require it. No hooks, no gates |
| 6. Maintain | The loop closes; a trigger invokes Claude with no person in the path | Partially, and only for the spec. `/sk:archive` merges the delta into `sk/specs/`, so the next change starts from what the last one actually established. Nothing is automatically triggered |

## The artifact chain

```
ADO work item  →  proposal.md  →  spec delta  →  tasks.md  →  diff  →  verify report  →  sk/specs/
   (intent)        (pointer)       (contract)     (plan)      (work)   (diff vs contract)  (what is true now)
```

For a direct request the first arrow collapses: `proposal.md` carries the request itself, so it is both intent and pointer.

Every arrow but the verify report is a file in version control; the report is response text, because it describes one moment of a diff that keeps changing. That is the property worth protecting: a reviewer who reads only the repository can reconstruct why a change exists, what it promised, and what it changed the system's obligations to be.

## What round 1 deliberately leaves out

- **Stage 5 gates.** No hooks as approval gates; `/sk:verify` reports but never blocks
- **Anything that writes to Azure DevOps.** The board stays authoritative for intent; SimplifyKit only reads it
- **A CLI.** There is no `sk validate` — artifact format is held by these conventions, the eval suite, and human review
