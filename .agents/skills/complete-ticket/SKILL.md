---
name: complete-ticket
description: Land a finished Jumbalaya ticket on main, mark Linear Done, and retire the issue so Free-plan issue slots are freed.
---

# Complete a Jumbalaya ticket

Land the work already produced by `/run-ticket` (code-developer, test-writer, code-reviewer). Do not re-run specialists, implement new scope, or start `/run-ticket` / `/create-ticket`.

Primary form: **`/complete-ticket ASH-<n>`** (for example `/complete-ticket ASH-5`). That invocation is approval to commit the ticket branch, merge it into `main`, and retire the Linear card.

## Linear Free plan (250 issues)

Prefer **delete after Done**, not archive.

Linear does **not** allow manual archive. Closed issues auto-archive only after the team's delay ([Linear: delete and archive](https://linear.app/docs/delete-archive-issues)). Completed issues still occupy the workspace until they are archived or deleted, so they keep counting toward the **250 Free issues** until then.

**This skill:** merge is the durable record (git on `main`). Then set Linear to **Done**, then **delete** the issue so the slot is free immediately. Deleted issues sit in Recently deleted for 30 days, then are gone. Git history and the merge commit remain.

Linear MCP can set **Done**; it cannot delete or archive. After Done, tell the user to delete the issue in Linear (`Cmd/Ctrl+Delete` or command palette → Delete issue). One-time: Ashwin team **Settings → Automations → auto-archive** at the shortest period as a safety net for any leftover Done cards.

Do not keep finished cards on the board to “save history.”

## Preconditions

Stop with a blocker (no merge) if any of these fail:

1. Linear `get_issue` for `ASH-<n>` succeeds.
2. Work branch is known: description `Branch:` line (for example `` `ash-5-main-menu-title` ``), else `ash-<n>-<slug>` from the title using the `/run-ticket` slug rules.
3. That branch exists locally.
4. `love tests` from the repository root **passes** (0 failed).
5. Working tree has no unrelated secrets (`.env`, credentials). Do not commit those files.

## Git (local, then main)

Do not force-push `main`. Do not skip hooks. Do not amend unless the user asked and the usual amend rules apply.

1. `git status --short --branch` and `git log -5 --oneline`.
2. Checkout the ticket branch.
3. If there are uncommitted ticket changes, stage them (not secrets) and commit with a 1–2 sentence message: why the ticket landed (issue id + title). Use a HEREDOC for the message.
4. Run `love tests`. If it fails, stop; do not merge.
5. Checkout `main` (or the default branch from `origin/HEAD`).
6. Merge the ticket branch (`git merge <branch>`). If conflicts, stop and report; do not invent resolutions beyond an obvious one-file fix the user would expect.
7. Push `main` to `origin` only if `origin` exists and tracks this repo. Never `--force` on `main`.
8. Stay on `main` after a successful merge.

Do not open a PR unless the user asks. This path is a local merge to `main`.

## Linear

After a successful merge:

1. `save_issue` `id: ASH-<n>` `state: Done`.
2. `save_comment` on the issue: merge landed on `main` (short SHA if known), branch name, `love tests` passed, leftover review items already on the issue if any.
3. Instruct the user to **delete** the issue in Linear now (Free 250). Confirm they should not rely on archive.

If Done fails, report the merge SHA and the Linear blocker; do not retry blindly.

## Output

- Issue id, branch, merge commit SHA, whether `main` was pushed.
- `love tests` result.
- Linear **Done** (or blocker).
- Explicit: **delete the Linear issue** to free a Free-plan slot; archive is automatic-only and too slow for the 250 cap.
- Confirmation that specialists were not re-run.
