# How SimplifyKit maps to the AI-native SDLC playbook

SimplifyKit follows [the AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook): every stage commits an artifact the next stage can read, and together those artifacts are the audit trail.

| Stage | Playbook | SimplifyKit, round 1 |
|---|---|---|
| 1. Plan | Intent captured once, in the originator's words, as a versioned artifact | **Already done, on the board.** The Azure DevOps work item *is* the intent artifact. `/sk:propose` reads it; it does not ask anyone to write it again. `proposal.md` is a pointer plus what the board does not hold — how the criteria were read, what was assumed, what is still open |
| 2. Design | Requirements and design in one session; policy applied while the spec is written | `/sk:propose` writes `specs/<capability>/spec.md` as a delta, and `design.md` when there is a real trade-off. Project policy arrives through `sk/config.yaml` → `rules`, applied while writing rather than reviewed afterwards |
| 3. Build | Nothing implemented without an accepted plan; institutional knowledge becomes files the agent reads | `/sk:apply` works `tasks.md` and refuses to start without it. Institutional knowledge is `sk/config.yaml` → `context`, which points at the repo's own docs instead of copying them |
| 4. Test | Every session checks its own work; the configuration that steers the agent is regression-tested | Partial. `/sk:apply` runs the repo's own build and tests. The **plugin's** configuration is regression-tested by `evals/` — that is the playbook's "configuration gets tested" applied to this kit itself. There is no `/sk:verify` yet |
| 5. Deploy | Review runs in both directions; governance enforced as the agent acts | Not in round 1. Review is human, through the diff and the artifacts. No hooks, no gates |
| 6. Maintain | The loop closes; a trigger invokes Claude with no person in the path | Partially, and only for the spec. `/sk:archive` merges the delta into `sk/specs/`, so the next change starts from what the last one actually established. Nothing is automatically triggered |

## The artifact chain

```
ADO work item  →  proposal.md  →  spec delta  →  tasks.md  →  diff  →  sk/specs/
   (intent)        (pointer)       (contract)     (plan)      (work)   (what is true now)
```

Every arrow is a file in version control. That is the property worth protecting: a reviewer who reads only the repository can reconstruct why a change exists, what it promised, and what it changed the system's obligations to be.

## What round 1 deliberately leaves out

- **Stage 5 entirely.** No hooks as approval gates, no automated review
- **Anything that writes to Azure DevOps.** The board stays authoritative for intent; SimplifyKit only reads it
- **Work with no work item.** Refactors, tech debt and spikes do not enter through `sk` yet
- **A CLI.** There is no `sk validate` — artifact format is held by these conventions, the eval suite, and human review
