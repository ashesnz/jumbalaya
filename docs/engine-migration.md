# Engine migration guide

Jumbalaya is migrating off the legacy Balatro-style engine pattern (global `G`, `G.GAME`, `G.FUNCS`, UIBox trees, live `CardArea` nodes) toward a **layered architecture** with a portable core, portable engine services, and a thin Love2D application shell.

**Phases 0–9 are complete.** This document describes the **current architecture**, **ongoing rules**, and **Phase 10+** work. Day-to-day package layout lives in [code-organization.md](code-organization.md).

---

## 1. Architecture today

```text
┌─────────────────────────────────────────────────────────────┐
│  app/                    Love2D shell (boot, lifecycle, I/O)  │
├─────────────────────────────────────────────────────────────┤
│  packages/jumbalaya-engine/   Clock, input, EventBus,         │
│                               retained_ui, PileView, …      │
├─────────────────────────────────────────────────────────────┤
│  word_game/              Glue + presentation + board geom   │
├─────────────────────────────────────────────────────────────┤
│  packages/jumbalaya_core/  Rules, store, reducers (no Love2D)│
├─────────────────────────────────────────────────────────────┤
│  bridge/                 runtime, funcs_registry, store_sync│
└─────────────────────────────────────────────────────────────┘
```

| Layer | Path | Responsibility |
|-------|------|----------------|
| Application | `app/` | Bootstrap (`engine_adapter`), `startup/`, Love2D callbacks, `app/core/` scene graph |
| Portable core | `packages/jumbalaya_core/` | Store, reducers, jumble rules, card data — headless-testable |
| Portable engine | `packages/jumbalaya-engine/` | Retained UI, views, input action map, event bus |
| This game | `word_game/` | Runtime glue (`model/`), UI (`ui/`), config, board |
| Bridge | `bridge/` | Wires layers at boot; migration shims |

**Do not delete `app/` or `packages/`.** `app/` runs the game; `packages/` holds libraries extracted for testing and future engine swaps. Overlap between `app/core/` and `jumbalaya-engine/` shrinks over Phase 10 — it is not accidental duplication to remove by merging trees.

### word_game vs jumbalaya_core

Most **rules** live in `jumbalaya_core`. `word_game/model/` modules are **runtime glue**: they call core, then read/write the live Game shell, store, and `Card` instances.

```text
jumbalaya_core  →  word_game/model (glue)  →  word_game/ui (presentation)
```

Glue files are often labeled *"glue over jumbalaya_core"* in their headers. **New gameplay logic:** implement in `jumbalaya_core` + `test_core_*` first; add the thinnest glue in `word_game/model/`.

---

## 2. Runtime buses (post–Phase 9)

There is **no global `G` singleton**. Production code uses these accessors:

| Concern | API | Notes |
|---------|-----|-------|
| Game shell | `bridge/runtime.lua` → `BridgeRuntime.game()` | Settings, timers, scene nodes (`dealt_letters`, `ROOM`, …) |
| Model shell | `word_game/model/live_game.lua` → `live_game()` | Same instance; used inside `word_game/model/` |
| UI shell | `word_game/ui/util/game_runtime.lua` | Same instance; used in presentation |
| Run snapshot | `WORD_GAME.store()` / `game_access.get()` | Authoritative run state; reducers in `jumbalaya_core` |
| UIBox callbacks | `bridge/funcs_registry.lua` | `Funcs.register`, `Funcs.dispatch`, `Funcs.get` |
| Model → UI | `Presentation.emit` | Contract: `types/presentation.lua` |
| Engine events | `WORD_GAME.engine().EventBus` | FX subscribers; bridged from Presentation |

UIBox definitions still use **string** `func = 'shuffle_hand'`. Strings are stable; dispatch goes through `Funcs`, not a table on the Game instance.

### Boot order

```text
main.lua
  → app/bootstrap/engine_adapter.lua
      → engine_boot      (scene graph classes, retained_ui)
      → runtime_boot     (Game(), store, facade, callbacks)
      → store_boot
      → presentation_boot
  → app/core/session/lifecycle.lua  (love.load → Game:launch)
```

`Game()` is constructed in `app/bootstrap/runtime_boot.lua`. `Game:construct` calls `bridge/runtime.bind_game(self)` — it does **not** assign a global `G`.

---

## 3. Completed migration (Phases 0–9)

| Phase | Deliverable | Location |
|-------|-------------|----------|
| **0** | Coupling inventory, freeze policy, store shim contract | `bridge/store_sync.lua`, `docs/code-organization.md` |
| **1** | `jumbalaya_core` package | `packages/jumbalaya_core/` |
| **2** | Store alongside live run state | `WORD_GAME.store()`, `game_access`, reducers |
| **3** | Engine service interfaces | `packages/jumbalaya-engine/` |
| **4** | Action dispatch for gameplay/settings | `bridge/action_dispatch.lua`, controllers |
| **5** | Pile state in store + dual-write | `bridge/pile_sync.lua`, `PileView`, `test_phase5_*` |
| **6** | View components + EventBus | `word_game/ui/views/`, `fx_subscribers.lua` |
| **7** | Slim bootstrap, store on `WORD_GAME` | `app/bootstrap/engine_adapter.lua` |
| **8** | Retire LayoutView / `app/core/ui/` | `jumbalaya-engine/retained_ui/` |
| **9** | Retire `G` singleton + `G.FUNCS` | `bridge/runtime.lua`, `bridge/funcs_registry.lua`, `types/funcs.lua` |

**Test baseline:** `love tests` → **487 passing**.

---

## 4. Phase 10 — Consolidation (current work)

Phase 10 removes **dual paths** left by the strangler migration. One PR per concern; keep `love tests` green after each.

### 10a — Glue hygiene (low risk)

**Goal:** `word_game/model/` is wiring only; no duplicated rule logic.

| Action | Detail |
|--------|--------|
| Audit glue modules | `round/`, `jumble/`, `jumble_play/`, `perks/` — move stray logic to `jumbalaya_core` |
| Config re-exports | Engine-agnostic tuning in `jumbalaya_core/config/`; `word_game/config/gameplay/{round,economy}.lua` stay as re-exports |
| Accessor consistency | Document: `live_game()` (model), `game_runtime` (UI), `BridgeRuntime.game()` (app/bridge) |
| Types | Fold `types/game.lua` run schema into `types/store.lua` (analyzer-only) |

**Exit:** New features add core rule + `test_core_*` before glue.

### 10b — Retire CardArea dual-write (medium risk)

**Goal:** Resting cards render from `store.piles` via `PileView` only. `CardArea` is for drag/interaction, then removed.

| Step | Work |
|------|------|
| 1 | TABLE_BOARD always draws hand/draw/pattern from store (remove CardArea-empty fallback) |
| 2 | Deal/shuffle/play mutate store; stop mirroring resting piles in `bridge/pile_sync.lua` |
| 3 | Save/load from store snapshots only |
| 4 | Shrink `word_game/ui/cardarea/` |

**Exit:** `rg 'CardArea' app word_game bridge` → 0 outside save-migration tests.

### 10c — Complete engine extraction (medium risk)

**Goal:** `packages/jumbalaya-engine` does not import `app/`.

| Action | Detail |
|--------|--------|
| Move | `app/core/scene/` (AnimNode, Node, …) into `jumbalaya-engine` |
| Shrink | `app/` to bootstrap + Love2D callbacks + startup |
| Update | `engine_boot.lua` loads engine package only |

**Exit:** `rg 'require\("app\.' packages/` → 0.

### 10d — Single state bus (after 10b)

**Goal:** One mutation path, one read path for run state.

| Action | Detail |
|--------|--------|
| Mutations | All via `game_access.dispatch` / store reducers |
| Reads | `game_access.get()` — not `live_game().GAME` in new code |
| Cleanup | Remove `bridge/store_sync` legacy helpers when unused |

---

## 5. Where to put new code

| Kind | Location | Test |
|------|----------|------|
| Pure rule | `packages/jumbalaya_core/` | `tests/unit/test_core_*.lua` |
| Runtime wiring | `word_game/model/` | `love tests` integration |
| Screen / FX | `word_game/ui/` | Manual smoke + unit where possible |
| Love2D boot / settings | `app/` | `test_boot_simulation.lua` |
| Jumble puzzle tables | `word_game/config/jumble/puzzles/` | Pattern tests |
| UIBox handler | `Funcs.register` in callbacks/controllers | `test_g_funcs_registry.lua` |

### Dependency rules

```text
jumbalaya_core          → (nothing in app/ or word_game/)
jumbalaya-engine        → jumbalaya_core, eventually not app/
word_game/model         → jumbalaya_core, bridge/, never word_game/ui/ at require time
word_game/ui            → word_game/model (via facade), app/core, jumbalaya-engine
app/                    → word_game/ at boot only
```

Cross-package entry points: **`WORD_GAME`** and **`WORD_GAME_UI`** facades.

---

## 6. Freeze policy (ongoing)

Until Phase 10b completes:

- **No new run-state keys** without owner in `types/game.lua` and a store field/reducer in `jumbalaya_core`.
- **No new UIBox callback names** without entry in `types/funcs.lua` (`test_g_funcs_registry.lua` enforces catalog).
- **No new rule logic** in `word_game/model/` — extend `jumbalaya_core` instead.
- **No new `LayoutView`** or `app/core/ui/` — use `jumbalaya-engine/retained_ui/`.
- New features ship via **facade methods** on `WORD_GAME` / `WORD_GAME_UI`.

---

## 7. Verification

### Every PR

```sh
love tests
emmylua_check . --severity warn    # CI uses error severity — see testing.md
```

### Migration grep gates

Run from repo root. Record deltas in PR descriptions when a gate moves.

```sh
# Global G reads in production (target: 0) — tests/devtools exempt
rg '\bG\.' --glob '*.lua' -g '!tests/**' -g '!devtools/**'

# Runtime .FUNCS reads (target: 0)
rg '\.FUNCS\b' app word_game packages

# CardArea live usage (target: 0 after Phase 10b)
rg -c 'CardArea' app word_game bridge packages -g '!tests/**'

# Engine package must not import app/ (target: 0 after Phase 10c)
rg 'require\("app\.' packages/

# Glue modules (should shrink, not grow)
rg -l 'glue over' word_game/model
```

### Current snapshot (2026-09-11, post–Phase 9)

| Metric | Value |
|--------|-------|
| `love tests` | **487** passed |
| `G.` in production | **0** |
| `CardArea` refs (app + word_game + bridge + packages) | **~72** |
| Glue modules in `word_game/model/` | **10** |
| `test_core_*` files | **14** |
| `Funcs.register` sites | **~59** |

Refresh: [engine-migration-coupling-inventory.md](engine-migration-coupling-inventory.md).

### Manual smoke (UI changes)

- Boot → menu → start run
- Play word / invalid word / hand clear
- Shuffle / hold-to-redraw
- Fuse expiry / trade / perk stamp
- Save/load mid-hand / End Run from sidebar

---

## 8. Test layers

```text
Layer 1  test_core_*           jumbalaya_core only — no Love2D, no boot
Layer 2  test_phase*_store_*    Store dispatch / reducers
Layer 3  test_* integration     Headless Love2D (mock_env)
Layer 4  Manual                 Animation timing, visual QA
```

Key suites: see [testing.md](testing.md#engine-migration-ci-gate-phase-0).

---

## 9. PR template (Phase 10+)

```markdown
## Phase 10 PR-__: ____

### Scope
- [ ] 10a glue / 10b CardArea / 10c engine extract / 10d state bus

### Grep delta
- G. production: __ → __
- CardArea: __ → __
- require("app.") in packages: __ → __
- glue modules: __ → __

### Automated
- [ ] love tests (487+)
- [ ] emmylua_check . --severity warn

### Manual smoke
- [ ] Boot → play → hand clear
- [ ] (other screens touched)
```

---

## 10. Risks and constraints

| Risk | Mitigation |
|------|------------|
| Save format break | Version store schema; `SAVE_ALIASES` in persistence |
| Animation regressions | Keep tweens/FX in `word_game/ui/play_effects/` — not in reducers |
| Circular requires | Core never imports engine; engine imports core only |
| Dual-state bugs | Store reducers own mutations; one writer rule |
| Card drag feel | Port snap math verbatim from `board/placement/snap.lua` |
| Boot-order bugs | `require` modules at top of file before use (e.g. `Funcs` before `Funcs.dispatch`) |

### Do not

- Merge `packages/` back into `app/` or delete either tree
- Move tweens into store reducers
- Big-bang menu + table + trade in one PR
- Duplicate rule logic in `word_game/model/` when it belongs in `jumbalaya_core`
- Extend legacy AP/plays/discards code

### Deferred / out of scope

- Full menu rewrite (retained UI is sufficient for now)
- `AlphaCardsBackup/` — reference only
- Alternative engine port (interfaces in `jumbalaya-engine` make it possible later)

---

## 11. Related docs

| Doc | Role |
|-----|------|
| [code-organization.md](code-organization.md) | Package map, callbacks, require conventions |
| [testing.md](testing.md) | Test helpers, CI gate list |
| [engine-migration-coupling-inventory.md](engine-migration-coupling-inventory.md) | Grep commands + metric snapshot |
| [gameplay.md](gameplay.md) | Player-facing systems |
| `types/game.lua`, `types/store.lua`, `types/funcs.lua` | Analyzer schemas |

---

## Appendix — Phase history (abbreviated)

<details>
<summary>Phases 0–9 summary (click to expand)</summary>

- **Phase 0:** Inventory, freeze policy, `bridge/store_sync` contract
- **Phase 1:** Extract `jumbalaya_core` (rules, store, config)
- **Phase 2:** Store authority + `game_access`
- **Phase 3:** `jumbalaya-engine` services (clock, input, audio, context)
- **Phase 4:** Controllers + `action_dispatch` for typed actions
- **Phase 5:** Pile state in store; `pile_sync` dual-write; `PileView`
- **Phase 6:** `word_game/ui/views/`; EventBus; FX subscribers
- **Phase 7:** `engine_adapter` bootstrap split; `WORD_GAME.store()` / `.engine()`
- **Phase 8:** Delete `app/core/ui/`; `retained_ui` in engine package
- **Phase 9:** `bridge/runtime`, `funcs_registry`, retire global `G` and `types/g_funcs.lua`

Full historical PR notes lived in git history prior to this doc rewrite.

</details>
