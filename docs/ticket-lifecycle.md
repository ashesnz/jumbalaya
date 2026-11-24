# Ticket lifecycle

This workflow adapts the ticket gate and specialist handoffs from the DTS reference to Jumbalaya's Love2D/Lua architecture. It does not assume an issue tracker or a specific branch workflow: paste the ticket and acceptance criteria when invoking a skill. No card is moved and no branch, commit, or PR is created automatically.

## Lifecycle

```text
Ticket + acceptance criteria
              ↓
         scrum-master
       Ready? ── no ──→ return blockers/questions; stop
              │ yes
              ↓
       code-developer
              ↓
         test-writer
              ↓
           love tests
              ↓
        code-reviewer (read-only)
              ↓
   Critical/actionable findings?
      yes → remediate and repeat verification + review (maximum two cycles)
      no  → report changes, checks, findings, and manual checks still needed
```

## Individual specialists

The Cursor subagents are defined in `.cursor/agents/`. Matching skill entry points are available under both `.cursor/skills/` and `.agents/skills/` so a specialist can be invoked directly or through its skill:

| Invocation | Responsibility |
|---|---|
| `/scrum-master` | Readiness gate for a concrete ticket; checks scope, testable acceptance criteria, project terminology, relevant current code, and material ambiguities. Does not implement. |
| `/code-developer` | Implements only the approved ticket scope, following the game/core/engine boundaries and local rules. |
| `/test-writer` | Adds meaningful coverage for gameplay logic, state transitions, math, and layout geometry using the existing Love2D harness. |
| `/code-reviewer` | Read-only review of the ticket changes for correctness, acceptance criteria, and project-rule violations. |
| `/run-ticket` | Orchestrates the full gated sequence below. |

Run an individual skill when you need only that specialist. Include the ticket and relevant acceptance criteria in the request; do not assume one specialist knows the context from another conversation. If a tool cannot actually delegate to the requested Cursor subagent, `/run-ticket` must report that limitation and stop rather than impersonating all four specialists.

## Readiness gate

`/scrum-master` starts from the ticket text provided by the user. It reads `AGENTS.md`, `docs/glossary.md`, and the applicable parts of `docs/code-organization.md`, `docs/gameplay.md`, and `docs/testing.md`; it inspects current code when a ticket uses an informal term or names an existing behavior. The glossary is code truth, while `docs/gameplay.md` is player-facing truth.

A ticket is **Ready** only when its title, optional summary, requirements, and acceptance criteria describe one coherent job; requirements fit that job; acceptance criteria are observable and testable; and no unresolved ambiguity would materially change behavior, architecture, or verification. A missing ticket, missing acceptance criteria, conflicting requirements, an undefined product decision, or a request that depends on a separate task is **Not ready**. For UI/layout work, the scrum master checks named surfaces and relevant callers, including shared-component variants and whether size, position, and content fit must remain unchanged. Exact gameplay values, dimensions, timing, and copy come from the ticket or authoritative Jumbalaya docs/current behavior, not an assumed reference build. The scrum master reports the exact blocker or question instead of inventing behavior. During `/run-ticket`, it does not pause to interview the user: it returns the blocker and the pipeline stops.

For a Ready result, the scrum master returns a self-contained approved brief: the ticket's scope and acceptance criteria, verified project/code facts that constrain implementation, and any explicit exclusions. The orchestrator passes this same brief to every later specialist; it does not broaden or reinterpret the approved scope. It stays in the conversation/delegation context and is not written to a guessed ticket tracker or a new ticket file.

## Full `/run-ticket` sequence

1. **Establish the baseline.** Record the existing working-tree status before changes. Preserve staged, unstaged, and untracked work; tell specialists which paths predate this ticket. Do not overwrite or review pre-existing changes as ticket output.
2. **Gate.** Delegate the full ticket to `scrum-master`. On Not ready, return its report and stop without code inspection or edits beyond what the gate needed.
3. **Implement.** Pass the approved brief and baseline paths to `code-developer`. The developer follows `AGENTS.md`, relevant `.cursor/rules/jumbalaya-*.mdc`, and the authoritative docs. It must not change branches or commit.
4. **Test.** Pass the same brief, developer's changed paths, and findings to `test-writer`. Logic tests belong in `games/jumbalaya/tests/unit/test_<feature>.lua`; the runner discovers these automatically, so do not manually register them. Use the existing test helpers and do not test constants or trivial wrappers.
5. **Verify.** Run the required full suite from the repository root with `love tests`. Do not claim success if it fails. Treat failures as change-related unless evidence shows otherwise; make a genuine attempt to resolve relevant failures without weakening assertions. Report proven pre-existing or unrelated failures as blockers and do not modify unrelated behavior to hide them.
6. **Review.** Delegate a read-only review to `code-reviewer`, providing the approved brief, baseline paths, all ticket changes, test output, and earlier findings. The review covers changed files only, including tests and workflow/configuration files when they are part of the ticket.
7. **Remediate.** Address Critical findings and actionable Warnings, then repeat full verification and read-only review. Allow at most two remediation cycles after the first review. Do not loop on Suggestions unless they prevent acceptance criteria from being met; report remaining findings.
8. **Report.** Summarize changed paths, acceptance-criteria status, `love tests` output, review findings, blockers, and manual checks still needed. Headless tests do not establish that interactive Love2D visuals or input flows work; say explicitly when those were not smoke-tested.

Each specialist receives a self-contained delegation brief: the approved ticket and exact acceptance criteria, that the work is a pipeline run, baseline/pre-existing paths, files changed so far, prior findings or test output, and its specific role. A specialist that cannot proceed returns a blocker; the orchestrator does not fill gaps by guessing.

## Jumbalaya-specific constraints

- Keep `packages/jumbalaya_core/` engine-agnostic and headless; keep `word_game/model/` as runtime glue and `word_game/ui/` as presentation. Respect the dependency and facade rules in `AGENTS.md` and `docs/code-organization.md`.
- Use `WORD_GAME` / `WORD_GAME_UI` facades across package boundaries. Do not reintroduce removed legacy AP/plays/discards gameplay or Vault terminology.
- The canonical game tests are in `games/jumbalaya/tests/`; root `tests/` is a shim for `love tests`. New `test_*.lua` suites under `games/jumbalaya/tests/unit/` are auto-discovered by its runner.
- After logic changes, run `love tests`. Run `emmylua_check . --severity warn` after structural refactors when applicable. Manual UI smoke checks are separate from headless tests.
- Preserve existing work. Do not change branches, stage, commit, push, or open a PR unless the user explicitly asks.
