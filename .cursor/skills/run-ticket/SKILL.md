---
name: run-ticket
description: Orchestrate the gated Jumbalaya ticket lifecycle through scrum-master, code-developer, test-writer, verification, and read-only review.
---

# Run a Jumbalaya ticket

You are the orchestrator. Do not implement, write tests, judge readiness, or review the diff yourself. Delegate each specialist stage to the named Cursor subagent and wait for its result before the next stage. If actual specialist delegation is unavailable, report that blocker and stop; do not silently impersonate all roles.

## Invocation

Primary form: **`/run-ticket ASH-<n>`** (for example `/run-ticket ASH-5`). The issue identifier is enough; do not require pasted ticket text when Linear returns title, description, and acceptance criteria.

Fallback (no Linear id): require the full ticket and acceptance criteria in the message. Do not create a branch or update Linear without an issue identifier.

If the user only asks whether a ticket is ready, delegate to `scrum-master` and stop.

## Delegation brief

Every specialist must receive a self-contained prompt containing:

- The complete ticket and exact approved acceptance criteria.
- That this is a pipeline run and the specialist's specific role.
- The scrum master's approved brief and verified code facts.
- The pre-run baseline paths that were already modified.
- The work branch name created for this run.
- Files changed so far and any prior findings or test output.

Specialists do not share context automatically. Do not expand or reinterpret the approved brief between stages. In a pipeline, answer questions from that brief or stop with a blocker; do not pause mid-run for a question the ticket does not answer.

## Linear and git bootstrap (issue id required)

Run these steps before the readiness gate when the user supplies a Linear issue id:

1. **Fetch issue:** Use the project's Linear MCP (`get_issue`) for the identifier (for example `ASH-5`). If Linear is unavailable, unauthenticated, or the issue is missing, return a blocker and stop.
2. **Baseline (before branch switch):** Record read-only `git status --short --branch`. Identify staged, unstaged, and untracked paths already present. Preserve them and tell every specialist what predates this ticket.
3. **Branch name:** Build `ash-<n>-<slug>` where:
   - `ash-<n>` is the issue key lowercased (`ASH-5` → `ash-5`).
   - `<slug>` comes from the issue title: lowercase; letters, digits, and spaces become words; non-alphanumerics become hyphens; collapse repeats; trim leading/trailing hyphens.
   - Truncate `<slug>` to **at most 16 characters**, then trim trailing hyphens. If empty, use `ticket`.
   - Example: title "Main menu title tile is off-centre…" → `ash-5-main-menu-title`.
4. **Create or checkout branch:** From the repository default branch when discernible (`origin/HEAD`, else `main`, else `master`, else current branch). If the branch already exists locally, check it out; otherwise `git checkout -b <branch>`. Do not commit, push, or open a PR.
5. **Linear In Progress:** `save_issue` with `state: In Progress` for that issue. Update the description `Branch:` line to the branch name (patch `Branch: Not assigned` or an existing `Branch:` line). If the status update fails, report a blocker and stop before implementation.

Specialists must not create, rename, or switch branches; the orchestrator owns bootstrap.

## Pipeline

1. **Readiness gate:** Delegate the entire ticket (from Linear or the user message) to `scrum-master`. It checks one-job scope, testable acceptance criteria, project glossary, relevant current behavior, and material ambiguity. If Not ready, return the report and stop without implementation. The branch and Linear status may already be updated; say so in the report.
2. **Implementation:** On Ready, pass the approved brief to `code-developer`. Keep changes within ticket scope and Jumbalaya's existing architecture. Preserve the baseline; no commit, push, or branch operations in specialists.
3. **Tests:** Pass the approved brief, implementation paths, and developer findings to `test-writer`. Meaningful game tests belong under `games/jumbalaya/tests/unit/test_<feature>.lua`; the runner auto-discovers them. Do not ask for tests of constants or trivial wrappers.
4. **Full verification:** Run `love tests` from the repository root and include the actual output/result in later briefs. **The pipeline does not succeed unless `love tests` passes.** If it fails, do not proceed as if it passed. Treat failures as change-related unless evidence proves otherwise, and send relevant failures to the appropriate specialist for a genuine fix. Do not skip tests, reduce assertions, or hide failures. If an unrelated/pre-existing failure cannot safely be resolved within ticket scope, report it as a blocker rather than changing unrelated behavior.
5. **Review:** Delegate read-only review to `code-reviewer` with the full ticket diff, baseline paths, all previous reports, and the full-suite result. Review only ticket changes; require actionable findings with file/line where practical.
6. **Remediation:** Pass every recommended finding (Criticals, Warnings, and Suggestions) to `code-developer`. Send test-only findings to `test-writer`. The developer must attempt each in-scope recommended fix. After each code/test change, rerun `love tests` and read-only review. Allow at most two remediation cycles after the first review. Remediation does not succeed until `love tests` passes.
7. **Linear leftovers:** After the last review cycle, if any recommended finding is still open, unfixed, or out of scope, post one comment on the Linear issue (`save_comment`) listing each leftover: severity, file/line when known, and why it was not done (out of scope, cycle cap, or developer deferred). Skip the comment if every finding was fixed. If Linear is unavailable, report the leftovers in the completion summary instead.
8. **Completion:** Report changed paths, acceptance-criteria status, `love tests` result, review findings, leftovers posted to Linear (or that none remained), blockers, and manual checks still needed. Headless tests do not verify interactive rendering, motion, or input. Do not claim a visual/UI AC passed unless the relevant Love2D smoke check was actually performed.

If a ticket changes Lua structure or boot globals, run `emmylua_check . --severity error` (CI). New `_G` Kind aliases need `.emmyrc.json` `diagnostics.globals`. Do not replace the required `love tests` run with a static check. `/complete-ticket` repeats the error-severity check before merge.

## Output

- Linear issue id, branch name, and In Progress update (or blocker).
- Readiness verdict and blocker, if any.
- Changed files and concise outcome.
- `love tests` command and pass/fail result; report other checks separately.
- Criticals, Warnings, Suggestions; which were fixed vs posted on Linear as leftovers.
- Manual Love2D smoke checks that remain outstanding.
- Explicit confirmation that **no commit, push, or PR** was performed (branch creation and checkout are expected when an issue id was provided). Landing on `main` is **`/complete-ticket ASH-<n>`**, not this skill.