# Engine migration — progress & consolidation plan

**Status:** Phase 10 active (post–Phase 9 complete)  
**Last updated:** 2026-09-12  
**Authoritative guide:** [engine-migration.md](engine-migration.md)  
**Grep snapshot:** [engine-migration-coupling-inventory.md](engine-migration-coupling-inventory.md)

This document tracks how far the repo is toward a **clean, understandable custom-engine architecture** and outlines the steps to finish consolidation without collapsing the wrong trees.

---

## 1. Goal (what “done” looks like)

```text
┌──────────────────────────────────────────────────────────────┐
│  app/                    Thin Love2D shell                    │
│                          bootstrap · lifecycle · callbacks      │
├──────────────────────────────────────────────────────────────┤
│  word_game/              Jumbalaya game (glue + presentation)   │
├──────────────────────────────────────────────────────────────┤
│  packages/jumbalaya-engine/   Custom engine (scene, input, UI) │
├──────────────────────────────────────────────────────────────┤
│  packages/jumbalaya_core/     Portable rules + store (no Love2D)│
└──────────────────────────────────────────────────────────────┘
         bridge/  →  dissolved (shims retired or moved home)
```

**Principles:**

- **One rule engine** — gameplay logic in `jumbalaya_core`, tested headlessly.
- **One custom engine** — scene graph, retained UI, input, clock, event bus in `jumbalaya-engine`.
- **One game layer** — `word_game/` wires core + engine to Jumbalaya-specific cards, puzzles, HUD.
- **One app shell** — `app/` boots Love2D and owns platform callbacks only.
- **One state bus** — `WORD_GAME.store()` / `game_access` for run snapshot reads and writes.
- **No duplicate rendering paths** — store-backed `PileView` only (no parallel `CardArea` mirror).

---

## 2. Do not merge everything into one folder

A common instinct is to put `packages/`, `word_game/`, and `app/` into a single tree. **That is not the target architecture** and would undo the migration benefits:

| Tree | Why it stays separate |
|------|------------------------|
| `packages/jumbalaya_core/` | Headless rules + store — no Love2D, no globals. Runs in `test_core_*` without boot. |
| `packages/jumbalaya-engine/` | Reusable custom engine — scene nodes, retained UI, input map. Eventually portable to another game or backend. |
| `word_game/` | This game's glue, config, board geometry, and presentation. |
| `app/` | Love2D entry, bootstrap order, platform I/O. Shrinks as engine extraction completes. |

**What to consolidate:** overlapping *code paths* (dual state, dual card piles, three runtime accessors), not the top-level folders.

---

## 3. `bridge/` (dissolved — Phase 11)

**Short answer:** The **folder** is gone; several **concerns** live under `app/` now.

| Module | Role today | Long-term home | Retire? |
|--------|------------|----------------|---------|
| `runtime.lua` | Bound `Game` shell accessor (`BridgeRuntime.game()`) | `app/runtime.lua` or method on `Game` | Move, not delete |
| `funcs_registry.lua` | UIBox string → handler (`Funcs.dispatch`) | `app/callbacks/funcs.lua` | Move, not delete |
| `store_sync.lua` | Store factory + legacy `Game.GAME` mirror helpers | `app/bootstrap/store_boot.lua` + `game_access` | Shrink → delete helpers |
| `pile_sync.lua` | Dual-write CardAreas ↔ store piles | — | **Delete** after Phase 10b |
| `action_dispatch.lua` | Input action → store / engine input | `app/input/` or `jumbalaya-engine/input` | Move |
| `event_bridge.lua` | `Presentation.emit` → `EventBus` | `app/bootstrap/presentation_boot.lua` (inline) | Inline |

`bridge/` was dissolved in Phase 11 (2026-09-12). `runtime` and `Funcs` APIs remain under `app/runtime.lua` and `app/callbacks/funcs.lua`; `jumbalaya-engine` still imports `app.runtime` for shell access (Phase 12 may inject context instead).

---

## 4. Progress snapshot

Metrics refreshed **2026-09-12** from repo root. Compare to post–Phase 9 baseline in [engine-migration-coupling-inventory.md](engine-migration-coupling-inventory.md).

| Metric | Post–Phase 9 (2026-09-11) | **Now (2026-09-12)** | Phase 10 target |
|--------|---------------------------|----------------------|-----------------|
| `love tests` | 487 passed | **488 passed, 0 failed** | all green |
| `G.` in production (`!tests`, `!devtools`) | 0 | **0** | 0 |
| `.FUNCS` runtime reads | 0 | **0** | 0 |
| `CardArea` refs (app + word_game + bridge + packages) | ~72 | **0** (renamed → `CardPile`) | 0 |
| `require("app.")` in `packages/` | 2 | **2** | 0 |
| Glue modules (`glue over` in `word_game/model/`) | 10 | **10** | shrink |
| `test_core_*` files | 14 | **14** | grow with rules |
| `Funcs.register` sites | ~59 | **59** | stable catalog |
| `bridge/` require sites | — | **0** (folder dissolved) | 0 |
| `pile_sync` active | yes | **deleted** (`word_game/model/piles.lua`, chrome always on) | deleted |

### Phase completion

| Phase | Scope | Status | Notes |
|-------|-------|--------|-------|
| **0–9** | Store, engine package, retained UI, `Funcs`, no global `G` | ✅ **Complete** | See [engine-migration.md §3](engine-migration.md#3-completed-migration-phases-09) |
| **10a** | Glue hygiene — model is wiring only | 🟡 **In progress** | `round/` done (PR 10a-1); jumble/ + perks/ next |
| **10b** | Retire `CardArea` dual-write | ✅ **Complete** | `pile_sync` deleted; store-authoritative piles; `CardPile` hosts drag only |
| **10c** | Engine extraction — no `app/` imports in packages | ✅ **Complete** | `Kind`, scene graph, draw helpers in `jumbalaya-engine/`; `app/core/*` shims |
| **10d** | Single state bus | ✅ **Complete** | `game_access` store-only; `legacy_mirror_*` / `sync_from_g` removed |
| **11** | Dissolve `bridge/` folder | ✅ **Complete** | `app/runtime`, `app/callbacks/funcs`, `app/input/action_dispatch`, `app/bootstrap/store_sync`; `event_bridge` inlined |
| **12** | Shrink `app/` to shell only | ✅ **Complete** | Engine code in `jumbalaya-engine/`; game FX in `word_game/ui/effects/`; `app/core` = session + persistence + platform only |

**Overall Phase 10 estimate:** ~15–20% complete (foundation done; consolidation work largely ahead).

### Step 0 complete (2026-09-12)

- ✅ `test_save_roundtrip` — `tests/helpers/save_fs.lua` routes save I/O through an in-memory table (Love2D save dir is outside the workspace in sandboxed runs).
- ✅ Production `G.` reads — **0** (grep gate clean; comment in `jumbalaya_core/init.lua` reworded to avoid false positive).
- ✅ [engine-migration-coupling-inventory.md](engine-migration-coupling-inventory.md) refreshed with this snapshot.

---

## 5. Where duplication lives today

Understanding *what* is duplicated clarifies *what* to merge.

### 5a. Runtime shell accessors (three names, one object)

| Accessor | Used by | Same instance? |
|----------|---------|----------------|
| `BridgeRuntime.game()` | `app/`, `bridge/`, engine retained_ui | Yes |
| `live_game()` | `word_game/model/` | Yes — delegates to `BridgeRuntime` |
| `game_runtime` (`word_game/ui/util/game_runtime.lua`) | `word_game/ui/` | Yes |

**Fix (Phase 10d / 11):** Document one canonical name per layer; optionally collapse `live_game` / `game_runtime` to thin aliases only. Do not add a fourth accessor.

### 5b. Run state (store vs `Game.GAME`)

| Read path | Status |
|-----------|--------|
| `WORD_GAME.store()` / `game_access.get()` | ✅ Preferred — authoritative |
| `live_game().GAME` / `shell.GAME` | Shell pointer only (synced at bind/teardown; not read in glue/UI) |
| `game_access.get()` / `dispatch()` | ✅ Store-only |

**Phase 10d done:** Store created at boot via `store_boot`; tests bind through `mock_env.publish_game`. Shell `GAME` pointer synced only at run bind/teardown for legacy save/boot paths.

### 5c. Card piles (CardArea vs store / PileView)

| Path | Role |
|------|------|
| `word_game/ui/cardarea/` | Live `Card` nodes in `CardArea` containers (drag, focus) |
| `store.piles` + `PileView` | Store-backed snapshot (Phase 5+) |
| `word_game/model/piles.lua` | Store sync + chrome release (replaces `pile_sync`) |

**Phase 10b complete:** Store-authoritative resting piles; `CardPile` hosts drag/focus only. `word_game/ui/cardarea/` remains until interaction ports to engine views.

### 5d. Engine vs shell (`app/core/` vs `jumbalaya-engine/`)

| Location | Contents |
|----------|----------|
| `jumbalaya-engine/boot.lua` | Engine load order (`Engine.Boot.install()`) — custom engine entry point |
| `jumbalaya-engine/scene/` | `Node`, `AnimNode`, animated motion |
| `jumbalaya-engine/object.lua` | `Kind` class system |
| `jumbalaya-engine/graphics/` | `Sprite`, particles, `FlowText`, draw helpers |
| `jumbalaya-engine/interaction/` | Router, focus, pointer, gamepad (was `app/core/input/`) |
| `jumbalaya-engine/sound/` | Audio worker, mixer, main-thread API (was `app/core/audio/`) |
| `jumbalaya-engine/util/` | tween, geometry, colour, pack, … (was `app/core/util/`) |
| `jumbalaya-engine/retained_ui/` | Panels, layout, hit testing |
| `word_game/ui/effects/` | Game-specific FX (easing, card_motion, dissolve, …; was `app/effects/`) |
| `app/core/session/` | Love2D frame loop glue |
| `app/core/persistence/` | Save queue + disk worker |
| `app/core/platform/` | Window, display |

**Phase 12 done:** `app/` has no scene graph classes. Engine boot is `jumbalaya-engine.boot`; `app/bootstrap/engine_boot.lua` delegates to it.

**Phase 12 follow-up (2026-09-12):** Stray shell modules folded into target tree (`callbacks/controllers/`, `callbacks/screen_wipe`, `callbacks/profile`, `input/actions`, `bootstrap/app_events`). `jumbalaya-engine/shell.lua` holds the bound Game shell; `app/runtime.lua` delegates to it. `app/bootstrap/shell_bind.lua` injects `app_events`, `Funcs`, and `action_dispatch` at boot. **`rg 'require\("app\.' packages/` → 0**.

### 5e. Rules vs glue (`word_game/model/` vs `jumbalaya_core/`)

Most rules already moved. **10 glue modules** remain (labeled *glue over jumbalaya_core*):

- `jumble/hand.lua`, `slots.lua`, `validation.lua`, `puzzle_spec.lua`
- `jumble_play/jumble_rules.lua`, `letter_modifier_effects.lua`
- `round/init.lua`
- `perks/registry.lua`, `effects.lua`, `voucher_discard.lua`

**Fix (Phase 10a):** Audit each file — if it contains rule logic, move to core; if it only wires Cards/store, keep and document.

---

## 6. Recommended step-by-step plan

Work **one PR per row**. Keep `love tests` green after each. Record grep deltas in the PR.

### Step 0 — Stabilize baseline ✅ (2026-09-12)

- [x] Fix `test_save_roundtrip` failures (`tests/helpers/save_fs.lua`).
- [x] Eliminate the remaining production `G.` read (was a comment false positive; reworded).
- [x] Refresh [engine-migration-coupling-inventory.md](engine-migration-coupling-inventory.md) with this snapshot.

### Step 1 — Phase 10a: Glue hygiene (low risk) 🟡 in progress

1. Pick one glue module per PR (`round/`, then `jumble/`, then `perks/`).
2. Move any stray rule logic into `jumbalaya_core` + `test_core_*`.
3. Ensure config re-exports stay one-liners (`word_game/config/gameplay/{round,economy}.lua`).
4. Fold `types/game.lua` run schema into `types/store.lua` (analyzer-only).

**10a-1 `round/` (done):**
- `normalize_saved_word_round` → `jumbalaya_core.round` + `test_core_round`
- `clear_if_inactive_hand` → `jumbalaya_core.jumble.hand` + `test_core_hand`
- `word_game/model/round/init.lua` uses `game_access.dispatch` only (removed duplicate store_sync dispatch path)
- Run schema folded into `types/store.lua`; `economy.lua` re-export comment added

**Exit:** Glue file count shrinks or stays flat; no new rule logic in `word_game/model/`.

### Step 2 — Phase 10b: Retire CardArea dual-write (highest impact)

1. **TABLE_BOARD draws from store** — hand/draw/pattern via `PileView`; remove CardArea-empty fallback in `word_game/ui/table/board.lua`.
2. **Deal/shuffle/play mutate store only** — stop mirroring resting piles in `bridge/pile_sync.lua`.
3. **Save/load from store snapshots** — `app/core/persistence/save.lua` and `run_save.lua` use pile IDs, not CardArea walks.
4. **Shrink `word_game/ui/cardarea/`** — keep only drag/interaction until ported, then delete.
5. Set `pile_sync.chrome_release_enabled()` to `true`, then delete `pile_sync.lua`.

**Exit:** `rg 'CardArea' app word_game bridge packages -g '!tests/**'` → 0.

### Step 3 — Phase 10c: Complete engine extraction (medium risk)

1. Move `app/core/scene/` (`Object`, `Node`, `AnimNode`, animated/*) → `jumbalaya-engine/scene/`.
2. Move co-dependent graphics (`sprite.lua`, `draw.lua`, `node_transform.lua`) as needed by scene nodes.
3. Update `engine_boot.lua` to load engine package paths only.
4. Fix `retained_ui` imports to use `jumbalaya-engine.scene` instead of `app.core.scene`.

**Exit:** `rg 'require\("app\.' packages/` → 0.

### Step 4 — Phase 10d: Single state bus (after 10b)

1. Route all mutations through `game_access.dispatch` / store reducers.
2. Replace `live_game().GAME` reads in glue/UI with `game_access.get()`.
3. Remove `store_sync.legacy_mirror_*` when tests bind store in `mock_env`.
4. Remove `store_sync.sync_from_g` one-time boot path if store is always created first.

**Exit:** No new `Game.GAME` reads outside persistence migration code.

### Step 5 — Phase 11: Dissolve `bridge/` (after 10b–10d)

| From | To |
|------|-----|
| `bridge/runtime.lua` | `app/runtime.lua` (or `Game.shell()`) |
| `bridge/funcs_registry.lua` | `app/callbacks/funcs.lua` |
| `bridge/action_dispatch.lua` | `app/input/action_dispatch.lua` |
| `bridge/event_bridge.lua` | Inline in `presentation_boot.lua` |
| `bridge/store_sync.lua` | Deleted or merged into `store_boot` |
| `bridge/pile_sync.lua` | Deleted (10b) |

Update `live_game.lua` and `game_runtime.lua` to point at new paths. Run codemod on ~150 require sites.

**Exit:** `bridge/` directory removed; `rg 'bridge/'` → docs/tests only.

### Step 6 — Phase 12: Shrink `app/` to shell (after 10c)

Target layout:

```text
app/
  bootstrap/          engine_adapter, runtime_boot, store_boot, presentation_boot
  callbacks/          Love2D + UIBox handler installers
  startup/            profile, window, assets, menu_boot
  input.lua           Love2D input callbacks
  error_handler.lua
  runtime.lua         (from bridge)
  core/
    session/          lifecycle, loop (Love2D frame glue only)
    persistence/      save queue (Love2D I/O)
    platform/         window, display
```

Everything else (`core/scene`, `core/graphics`, `core/input`, `core/audio`, `effects/`) lives under `packages/jumbalaya-engine/` or `word_game/ui/` (game-specific FX).

**Exit:** `app/` has no scene graph classes; `jumbalaya-engine` is the custom engine entry point.

### Step 7 — Optional repo layout (future, not urgent)

Only consider after Phases 10–12 are complete:

```text
packages/
  jumbalaya_core/
  jumbalaya-engine/
games/
  jumbalaya/
    app/          # thin shell
    word_game/    # game layer
```

This is cosmetic reorganisation — same dependency rules, clearer monorepo story for a second game.

---

## 7. Dependency rules (unchanged — enforce during consolidation)

```text
jumbalaya_core          → (nothing in app/ or word_game/)
jumbalaya-engine        → jumbalaya_core only (shell callbacks injected at boot via app/bootstrap/shell_bind)
word_game/model         → jumbalaya_core, app/runtime (post-11), never word_game/ui/
word_game/ui            → jumbalaya-engine, word_game/model (facade), app/runtime
app/                    → word_game/ at boot only; no jumble rules
```

Cross-package entry points: **`WORD_GAME`** and **`WORD_GAME_UI`** facades.

---

## 8. What to work on next (priority order)

1. **Fix save roundtrip tests** — unblocks confident 10b persistence work.
2. **Phase 10b PR-1** — TABLE_BOARD reads piles from store only (feature-flagged draw path).
3. **Phase 10c PR-1** — move `Object` / `Node` / `AnimNode` into `jumbalaya-engine` (unblocks removing `app` import from retained_ui).
4. **Phase 10a** — one glue module audit per PR in parallel if multiple contributors.
5. **Phase 10d + 11** — after CardArea retirement.

Avoid big-bang PRs that touch menu + table + trade + bridge in one diff.

---

## 9. Verification checklist (every PR)

```sh
love tests
emmylua_check . --severity warn

# Migration gates
rg '\bG\.' --glob '*.lua' -g '!tests/**' -g '!devtools/**'
rg 'CardArea' app word_game bridge packages -g '!tests/**'
rg 'require\("app\.' packages/
rg -l 'glue over' word_game/model
rg 'bridge/' --glob '*.lua' -g '!docs/**'
```

Manual smoke when touching UI: boot → play → hand clear → shuffle → fuse → trade → save/load → End Run.

---

## 10. Related docs

| Doc | Role |
|-----|------|
| [engine-migration.md](engine-migration.md) | Phase definitions, freeze policy, PR template |
| [engine-migration-coupling-inventory.md](engine-migration-coupling-inventory.md) | Grep commands + metric history |
| [code-organization.md](code-organization.md) | Package map and callback ownership |
| [testing.md](testing.md) | CI gates and test tiers |
