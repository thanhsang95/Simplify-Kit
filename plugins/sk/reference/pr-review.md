# Reviewing a pull request — `/sk:verify --pr <id> [<worktree-path>]`

Read by `/sk:verify` when the request carries `--pr`: reviewing a pull request someone else opened, on the reviewer's machine. Everything else in `/sk:verify` applies; this file only says what changes.

1. Read the PR and its threads over REST as `${CLAUDE_PLUGIN_ROOT}/reference/azure-devops.md` → `## Pull requests (read-only)` says — never `az repos` or `az devops invoke`. U+FFFD in the title or description → stop and report. A failed fetch → report the error and stop; never invent PR content
2. **No path → print the commands and stop.** Never run them: both write to the repository's `.git/`.
   ```bash
   git fetch origin <source-branch> <target-branch>
   git worktree add ../<repo>-pr-<id> origin/<source-branch>
   ```
   then `/sk:verify --pr <id> ../<repo>-pr-<id>`
3. **With a path**, review there. Base is the PR's target branch: `origin/<target-branch>` in `/sk:verify` Step 3
4. **The standard**, first that exists: an open change in the worktree's `sk/changes/` whose id carries the AB# from the description or the branch name → as usual. Else the requirements the PR added or modified under `sk/specs/` (`git diff origin/<target>...HEAD -- sk/specs`) are the standard for `/sk:verify` Steps 4–5 — the usual case, since `archive/` is gitignored; no tasks to count, and the design and contract checks go under **Skipped**. Else no-change mode
5. **Previous round**: the latest thread comment starting `## Verification report:` (`/sk:verify` Step 2). Threads unreadable → say so and number from V1
6. **`sk/config.yaml` comes from the target branch** (`git show origin/<target>:sk/config.yaml`), never the worktree's — otherwise the PR's author decides what runs on the reviewer's machine. The PR changes `sk/config.yaml` or a test script or runner config → show that diff and ask before running tests; nobody to ask → do not run them, and say so
7. End with `git worktree remove <path>` for the user to run

Why the worktree is the person's step: `git fetch` writes refs and objects and `git worktree add` writes `.git/worktrees/`, both inside the repository `/sk:verify` promises not to write to. Why the config comes from the target branch: a PR that edits its own test command or drops a `sensitive:` glob would otherwise decide what runs, and what is checked, on the reviewer's machine.
