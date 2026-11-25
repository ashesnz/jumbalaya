# DRY practices (code developer)

Guidance for the **code-developer** agent and human contributors implementing Jumbalaya changes. This document complements `AGENTS.md` and `docs/code-organization.md`: architecture and boundaries stay authoritative; here we describe **how** to shape code inside an approved ticket.

The code developer acts as a **senior Love2D/Lua developer**: ship the ticket first, but leave touched code easier to read, free of obvious dead weight, and no more duplicated than the architecture warrants.

## Scope and ticket discipline

- **Ticket scope wins.** Hygiene applies primarily to **files and symbols you touch** for the ticket. Do not turn a bugfix into a repo-wide cleanup.
- **No drive-by refactors** in unrelated modules. If you spot systemic duplication or dead code outside the ticket, note it in the handoff (or a Linear comment in a pipeline) instead of fixing it silently.
- **Preserve baseline work** on the branch; do not claim unrelated local edits as ticket work.

When hygiene and acceptance criteria conflict, **meet the ACs** and report the tradeoff.

## Readability

Optimize for the next reader on this codebase (facades, store, presentation, Love2D shell).

- **Match the neighborhood.** Before adding APIs or patterns, read the owning module and its tests; mirror naming, require style, and abstraction depth.
- **Names over comments.** Use `snake_case` locals, `PascalCase` types, and terms from `docs/glossary.md` (e.g. **sidebar**, not vault). Prefer a clear function or field name to a comment that repeats the code.
- **Comments:** Explain non-obvious business rules, scheduler ordering, or cross-package contracts. Do not narrate obvious control flow. File headers already document Core / Store / Presentation where required.
- **Structure:** Keep hot paths (`update`, `draw`, deal/play) flat; hoist `require()` to module scope per `AGENTS.md`. Push pure rules into `jumbalaya_core`; keep glue in `word_game/model/`; keep motion and panels in `word_game/ui/` or `jumbalaya-engine/`.
- **Love2D specifics:** Respect boot order (`app/bootstrap.lua`), timeline/schedulers for sequencing (do not block the frame loop), and scene attachment (`set_rect`, `follow`, `bind_to`) instead of ad-hoc globals. Do not add new `love.*` calls in portable packages.

## Dead code

Look for dead code **in the path you are changing**:

| Signal | Action |
|--------|--------|
| Unreachable branches after your change | Remove if safe and verifiable |
| Unused locals, requires, or private helpers in touched files | Remove when the compiler/tests still pass |
| Legacy stubs, commented-out blocks, or names flagged removed in `AGENTS.md` | Do not reintroduce; remove only if the ticket owns that removal |
| Catalogued callbacks (`types/funcs.lua`) or presentation events | Do not delete registrations without removing all UI/model sites and tests |

**Verify:** Run `love tests` for logic changes. If you remove a symbol that might be used via dynamic dispatch (`Funcs.dispatch`, string actions), grep the repo before deleting.

**Do not** remove code you cannot prove unused (reflection, devtools-only paths, feature flags) without a product decision.

## Duplication (DRY with judgment)

**Default:** Prefer one clear source of truth per layer (core rule, reducer, facade method, panel definition).

**Duplication is acceptable** when it protects boundaries or clarity:

| Situation | Why duplication can be right |
|-----------|------------------------------|
| **Package boundary** | `jumbalaya_core` must not import `word_game/`; a thin repeat at the glue layer is cheaper than a leaky abstraction |
| **Presentation vs model** | UI mirrors store fields for layout; model emits events, UI subscribes — do not merge into one god module |
| **Boot vs test** | Tests use `mock_env` and fixtures; production uses facades — shared helpers belong in documented test helpers, not in core |
| **Incidental similarity** | Two call sites need the same three lines but different failure modes or lifetimes — extracting a one-off helper obscures intent |
| **Stability** | String `Funcs` names and frozen panel trees stay duplicated until a deliberate migration slice |

**Avoid unnecessary duplication** when:

- The same literal or formula appears **three or more times** in one package with the same semantics — extract to an existing util or a named local function in the same file.
- Copy-paste spreads bug fixes across siblings — centralize in the owning module (e.g. `piles.lua`, `sidebar/layout.lua`).
- Two modules implement the same **rule** — move the rule to `jumbalaya_core` and add `test_core_*` first.

**Anti-patterns:** Mega-util files, parameter-heavy generics for a single call site, or cross-package “helper” requires that violate `test_facade_boundaries.lua`.

## Senior developer checklist (per change)

Before handing off, for touched code:

1. **Correct layer** — Rule in core, wiring in model, pixels in UI, shell in `app/`.
2. **Minimal diff** — Smallest change that satisfies the ticket and hygiene above.
3. **No new leaks** — No deep requires across facades; no Love2D in core; no model → UI imports.
4. **Registrations** — New store fields, facade methods, or string callbacks follow catalog/registry tests.
5. **Globals** — New boot `_G` Kinds listed in `.emmyrc.json` when used without `require`.
6. **Report** — List readability tweaks, dead code removed, or duplication you intentionally left (with one-line why).

## Relationship to review and tests

- **code-reviewer** judges ticket fit and architecture; this doc guides **implementation quality** inside that scope.
- **test-writer** owns new behavioral coverage in pipelines; code-developer may add a focused test when asked standalone, but does not delete tests to force green.
- Headless tests do not prove animation or input feel; call out manual Love2D smoke when UI timing changes.

## See also

- `AGENTS.md` — dependency rules, facades, verification
- `docs/code-organization.md` — layers, store, freeze policy
- `docs/engine.md` — scene graph and motion
- `docs/testing.md` — harness and conventions
- `.cursor/agents/code-developer.md` — agent role and handoff