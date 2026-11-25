# Ticket lifecycle

This workflow adapts the ticket gate and specialist handoffs from the DTS reference to Jumbalaya's Love2D/Lua architecture. **`/run-ticket ASH-<n>`** loads the issue from Linear, creates a work branch, and moves the card to **In Progress** before the readiness gate. Paste the full ticket only when no Linear id is given. The pipeline does not commit, push, or open a PR; it must not report success unless `love tests` passes. **`/complete-ticket ASH-<n>`** commits that branch, merges it into `main`, marks Linear **Done**, and retires the card (delete on Free).

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
              ↓
    /complete-ticket ASH-<n>
       commit branch → merge main → Linear Done → delete issue (Free 250)
```

## Individual specialists

The Cursor subagents are defined in `.cursor/agents/`. Matching skill entry points are available under both `.cursor/skills/` and `.agents/skills/` so a specialist can be invoked directly or through its skill:

| Invocation | Responsibility |
|---|---|
| `/scrum-master` | Readiness gate for a concrete ticket; checks scope, testable acceptance criteria, project terminology, relevant current code, and material ambiguities. Does not implement. |
| `/code-developer` | Implements only the approved ticket scope, following the game/core/engine boundaries and local rules. |
| `/test-writer` | Adds meaningful coverage for gameplay logic, state transitions, math, and layout geometry using the existing Love2D harness. |
| `/code-reviewer` | Read-only review of the ticket changes for correctness, acceptance criteria, and project-rule violations. |
| `/run-ticket` | Orchestrates the full gated sequence below. With a Linear id (for example `ASH-5`), fetches the issue, branches as `ash-<n>-<slug≤16>`, sets **In Progress**, then runs specialists locally. |
| `/complete-ticket` | Lands `/run-ticket` work on `main` (commit + merge), sets Linear **Done**, then the issue is **deleted** so it stops counting toward Linear Free’s 250 issues. Does not re-run specialists. |

Run an individual skill when you need only that specialist. Include the ticket and relevant acceptance criteria in the request; do not assume one specialist knows the context from another conversation. If a tool cannot actually delegate to the requested Cursor subagent, `/run-ticket` must report that limitation and stop rather than impersonating all four specialists.

## Readiness gate

`/scrum-master` starts from the ticket text provided by the user. It reads `AGENTS.md`, `docs/glossary.md`, and the applicable parts of `docs/code-organization.md`, `docs/gameplay.md`, and `docs/testing.md`; it inspects current code when a ticket uses an informal term or names an existing behavior. The glossary is code truth, while `docs/gameplay.md` is player-facing truth.

A ticket is **Ready** only when its title, optional summary, requirements, and acceptance criteria describe one coherent job; requirements fit that job; acceptance criteria are observable and testable; and no unresolved ambiguity would materially change behavior, architecture, or verification. A missing ticket, missing acceptance criteria, conflicting requirements, an undefined product decision, or a request that depends on a separate task is **Not ready**. For UI/layout work, the scrum master checks named surfaces and relevant callers, including shared-component variants and whether size, position, and content fit must remain unchanged. Exact gameplay values, dimensions, timing, and copy come from the ticket or authoritative Jumbalaya docs/current behavior, not an assumed reference build. The scrum master reports the exact blocker or question instead of inventing behavior. During `/run-ticket`, it does not pause to interview the user: it returns the blocker and the pipeline stops.

For a Ready result, the scrum master returns a self-contained approved brief: the ticket's scope and acceptance criteria, verified project/code facts that constrain implementation, and any explicit exclusions. The orchestrator passes this same brief to every later specialist; it does not broaden or reinterpret the approved scope. It stays in the conversation/delegation context and is not written to a guessed ticket tracker or a new ticket file.

## Full `/run-ticket` sequence

### Invocation

- **`/run-ticket ASH-5`** — issue body comes from Linear; no paste required.
- **`/run-ticket`** with pasted ticket — no Linear bootstrap (no branch, no status change) unless an issue id is included.

### Branch naming

`ash-<n>-<slug>`: lowercased issue key, hyphen, then a slug from the title truncated to **16 characters** (for example `ash-5-main-menu-title`). See `.cursor/skills/run-ticket/SKILL.md` for slug rules.

### Steps

1. **Linear + branch (when id present).** `get_issue`, baseline `git status` on the current branch, create or checkout the work branch from the default branch, set Linear to **In Progress**, patch the issue description `Branch:` line.
2. **Establish the baseline.** Record which paths predated this ticket (captured before the branch switch). Preserve staged, unstaged, and untracked work; tell specialists which paths predate this ticket. Do not overwrite or review pre-existing changes as ticket output.
3. **Gate.** Delegate the full ticket to `scrum-master`. On Not ready, return its report and stop without implementation (branch and Linear status may already be updated).
4. **Implement.** Pass the approved brief and baseline paths to `code-developer`. The developer follows `AGENTS.md`, relevant `.cursor/rules/jumbalaya-*.mdc`, and the authoritative docs. It must not change branches or commit.
5. **Test.** Pass the same brief, developer's changed paths, and findings to `test-writer`. Logic tests belong in `games/jumbalaya/tests/unit/test_<feature>.lua`; the runner discovers these automatically, so do not manually register them. Use the existing test helpers and do not test constants or trivial wrappers.
6. **Verify.** Run the required full suite from the repository root with `love tests`. **Success requires a passing run.** Do not claim success if it fails. Treat failures as change-related unless evidence shows otherwise; make a genuine attempt to resolve relevant failures without weakening assertions. Report proven pre-existing or unrelated failures as blockers and do not modify unrelated behavior to hide them.
7. **Review.** Delegate a read-only review to `code-reviewer`, providing the approved brief, baseline paths, all ticket changes, test output, and earlier findings. The review covers changed files only, including tests and workflow/configuration files when they are part of the ticket.
8. **Remediate.** Pass every recommended finding (Criticals, Warnings, Suggestions) to `code-developer` (and `test-writer` for test-only findings). The developer must attempt each in-scope recommended fix. Repeat full verification and read-only review. Allow at most two remediation cycles after the first review. Remediation is not complete until `love tests` passes.
9. **Linear leftovers.** After the last review cycle, post one Linear comment on the issue listing any recommended findings that were not fixed or were out of scope, with file/line and reason. Skip the comment if nothing remains.
10. **Report.** Summarize issue id, branch name, changed paths, acceptance-criteria status, `love tests` output, review findings, leftovers posted to Linear, blockers, and manual checks still needed. Confirm no commit, push, or PR. Headless tests do not establish that interactive Love2D visuals or input flows work; say explicitly when those were not smoke-tested.

Each specialist receives a self-contained delegation brief: the approved ticket and exact acceptance criteria, that the work is a pipeline run, baseline/pre-existing paths, files changed so far, prior findings or test output, and its specific role. A specialist that cannot proceed returns a blocker; the orchestrator does not fill gaps by guessing.

## Completing a ticket (`/complete-ticket`)

Invoke **`/complete-ticket ASH-5`** after `/run-ticket` has finished (green `love tests`, review leftovers commented on Linear if any). This is approval to land the work. See `.cursor/skills/complete-ticket/SKILL.md` (mirrored under `.agents/skills/`).

1. Checkout the issue’s work branch, commit remaining ticket changes, run `love tests` (must pass) and `emmylua_check . --severity error` (must pass; same as CI).
2. Merge that branch into **`main`**. Push `origin/main` when a remote exists. Never force-push `main`. No PR unless asked.
3. Set the Linear issue to **Done** and comment with the merge SHA.
4. **Delete** the Linear issue (Free plan). Linear cannot be archived by hand; auto-archive is delayed and **Done** cards still count toward **250 issues** until archived or deleted. Git on `main` is the record. Linear MCP cannot delete: after Done, delete in the Linear UI (`Cmd/Ctrl+Delete`). Optional one-time: team **Settings → Automations** → shortest auto-archive for any leftover Done issues.

Do not re-run scrum-master, code-developer, test-writer, or code-reviewer during complete.

## Creating issues in Linear from Cursor

The project provides a `/create-ticket` skill in `.cursor/skills/create-ticket/` (mirrored under `.agents/skills/`). It asks focused questions before creating anything when an idea is materially vague, drafts the issue in the format below, and asks the `scrum-master` agent to check readiness. It is separate from `/run-ticket`: creating an issue never implements it or starts the implementation pipeline.

### Connect Linear

The project-level `.cursor/mcp.json` configures Linear's hosted MCP server at `https://mcp.linear.app/mcp`. Open the project in Cursor, enable the Linear MCP server if prompted, and complete Linear's OAuth authorization in Cursor. Do not add a personal API token to the repository. Issue creation requires the read-write Linear MCP connection; a read-only connection cannot create issues. See [Linear's Cursor MCP setup](https://linear.app/docs/mcp#cursor) and [Cursor MCP integration](https://linear.app/integrations/cursor-mcp).

### Create a ticket

Invoke `/create-ticket` with an idea, for example `/create-ticket make the buttons rounded with a 5px radius`. The skill asks about missing information that could materially affect scope, behavior, or testing before presenting a create approval. New issues are always created on team Ashwin, assigned to Ashwin, in Backlog (project Jumbalaya). If you want to capture an unresolved idea anyway, it leaves the gaps under **Open questions**, does not call it Ready, and still uses Backlog. No branch is created: an unknown branch is shown as `Not assigned`.

The description template keeps the supplied rationale and test details, without inventing missing facts:

```text
Branch: <branch name or Not assigned>
#<Linear number> <Title>

## Goal
<Outcome and reason>

## Requirements
- <Requirement>
  Why: <Rationale, when supplied>

## Words used on this card:
- <Term>: <Meaning>

## Acceptance criteria
- <Observable result>

## How to test
- <Setup, action, and expected result>

## Out of scope
- <Explicit exclusions>

## Open questions
- <Unresolved decision>
```

The final Linear issue title is `#<Linear number> - <Title>`; its identifier's numeric part is used (for example, `ASH-275` becomes `#275`). Since Linear only assigns the number on creation, numbering needs two approvals: first, the skill displays and asks approval for an unnumbered provisional issue in Backlog (including a `#Pending <Title>` line in its description); after creation, it shows the confirmed numbered title and full description and asks approval to update that same issue. The provisional issue is visible on the board between those approvals. If the second approval is declined, it remains in Backlog unnumbered. This avoids guessing the next issue number.

`/create-ticket` always creates on Linear team **Ashwin**, project **Jumbalaya**, assigned to **Ashwin**, in **Backlog**. It does not ask for another team, project, or starting state. Every new issue starts in Backlog, including Ready drafts; never create into Ready, Todo, or In Progress. It shows the exact content and this destination before each write and requires explicit approval for each operation. If MCP authorization, permissions, or a create/update result is uncertain, it reports the blocker and verifies the existing issue rather than blindly retrying or claiming success. No account identifiers need to be written in project configuration.

This integration creates issues only. **`/run-ticket ASH-<n>`** (orchestrator) moves issues to **In Progress** and sets the description `Branch:` field; it does not require Linear → Cursor cloud automations. See [Cursor Automations](https://cursor.com/docs/cloud-agent/automations#linear-triggers) only if you want a status change in Linear to start a cloud agent instead of local `/run-ticket`.

## Jumbalaya-specific constraints

- Keep `packages/jumbalaya_core/` engine-agnostic and headless; keep `word_game/model/` as runtime glue and `word_game/ui/` as presentation. Respect the dependency and facade rules in `AGENTS.md` and `docs/code-organization.md`.
- Use `WORD_GAME` / `WORD_GAME_UI` facades across package boundaries. Do not reintroduce removed legacy AP/plays/discards gameplay or Vault terminology.
- The canonical game tests are in `games/jumbalaya/tests/`; root `tests/` is a shim for `love tests`. New `test_*.lua` suites under `games/jumbalaya/tests/unit/` are auto-discovered by its runner.
- After logic changes, run `love tests`. Run `emmylua_check . --severity warn` after structural refactors when applicable. Manual UI smoke checks are separate from headless tests.
- Preserve existing work. The `/run-ticket` orchestrator may create and checkout a work branch when given a Linear id. `/complete-ticket` may commit that branch and merge it into `main`. Otherwise do not change branches, stage, commit, push, or open a PR unless the user explicitly asks.
