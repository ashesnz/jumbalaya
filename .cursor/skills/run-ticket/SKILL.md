---
name: run-ticket
description: Orchestrate the gated Jumbalaya ticket lifecycle through scrum-master, code-developer, test-writer, verification, and read-only review.
---

# Run a Jumbalaya ticket

You are the orchestrator. Do not implement, write tests, judge readiness, or review the diff yourself. Delegate each specialist stage to the named Cursor subagent and wait for its result before the next stage. If actual specialist delegation is unavailable, report that blocker and stop; do not silently impersonate all roles.

If the user only asks whether a ticket is ready, delegate to `scrum-master` and stop. Otherwise, require the full ticket and acceptance criteria. If they are absent, return one blocker. Do not assume a tracker, branch name, branch creation, commit, push, or PR.

## Delegation brief

Every specialist must receive a self-contained prompt containing:

- The complete ticket and exact approved acceptance criteria.
- That this is a pipeline run and the specialist's specific role.
- The scrum master's approved brief and verified code facts.
- The pre-run baseline paths that were already modified.
- Files changed so far and any prior findings or test output.

Specialists do not share context automatically. Do not expand or reinterpret the approved brief between stages. In a pipeline, answer questions from that brief or stop with a blocker; do not pause mid-run for a question the ticket does not answer.

## Pipeline

1. **Baseline:** Before any changes, record read-only `git status --short --branch` and identify staged, unstaged, and untracked paths already present. Preserve them and tell every specialist what predates this ticket. Do not assume the current branch is a base branch or switch branches.
2. **Readiness gate:** Delegate the entire ticket to `scrum-master`. It checks one-job scope, testable acceptance criteria, project glossary, relevant current behavior, and material ambiguity. If Not ready, return the report and stop without implementation.
3. **Implementation:** On Ready, pass the approved brief to `code-developer`. Keep changes within ticket scope and Jumbalaya's existing architecture. Preserve the baseline; no branch or commit operations.
4. **Tests:** Pass the approved brief, implementation paths, and developer findings to `test-writer`. Meaningful game tests belong under `games/jumbalaya/tests/unit/test_<feature>.lua`; the runner auto-discovers them. Do not ask for tests of constants or trivial wrappers.
5. **Full verification:** Run `love tests` from the repository root and include the actual output/result in later briefs. If it fails, do not proceed as if it passed. Treat failures as change-related unless evidence proves otherwise, and send relevant failures to the appropriate specialist for a genuine fix. Do not skip tests, reduce assertions, or hide failures. If an unrelated/pre-existing failure cannot safely be resolved within ticket scope, report it as a blocker rather than changing unrelated behavior.
6. **Review:** Delegate read-only review to `code-reviewer` with the full ticket diff, baseline paths, all previous reports, and the full-suite result. Review only ticket changes; require actionable findings with file/line where practical.
7. **Remediation:** Fix Critical findings and actionable Warnings; do not spend cycles on Suggestions unless acceptance is blocked. After each code/test change, rerun `love tests` and read-only review. Allow at most two remediation cycles after the first review; report any unresolved issue when the cap is reached.
8. **Completion:** Report changed paths, acceptance-criteria status, `love tests` result, review findings, blockers, and manual checks still needed. Headless tests do not verify interactive rendering, motion, or input. Do not claim a visual/UI AC passed unless the relevant Love2D smoke check was actually performed.

If a ticket changes Lua structure materially, include `emmylua_check . --severity warn` when applicable. Do not replace the required `love tests` run with a static check.

## Output

- Readiness verdict and blocker, if any.
- Changed files and concise outcome.
- `love tests` command and pass/fail result; report other checks separately.
- Criticals, actionable Warnings, remaining Suggestions, or unresolved blockers.
- Manual Love2D smoke checks that remain outstanding.
- Explicit confirmation that no branch, commit, or PR operation was performed.
