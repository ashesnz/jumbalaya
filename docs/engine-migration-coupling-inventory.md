# Engine migration — coupling snapshot

Post–Phase 9 metrics. Refresh before Phase 10 PRs that claim a grep delta.

**Authoritative guide:** [engine-migration.md](engine-migration.md)  
**Package rules:** [code-organization.md](code-organization.md)

---

## Summary (2026-09-12, Step 0 baseline)

| Metric | Post–Phase 9 (2026-09-11) | **Now** | Phase 10 target |
|--------|---------------------------|---------|-----------------|
| `love tests` | 487 passed | **490 passed, 0 failed** | stay green |
| `G.` in production (`!tests`, `!devtools`) | 0 | **0** | **0** |
| `.FUNCS` runtime reads | 0 | **0** | **0** |
| `CardArea` (app + word_game + bridge + packages) | ~72 | **0** (renamed → `CardPile`) | **0** (10b) |
| `require("app.")` in `packages/` | 2 (`retained_ui` → AnimNode) | **2** | **0** (10c) |
| Glue modules (`glue over` in `word_game/model/`) | 10 | **10** | shrink (10a) |
| `test_core_*` files | 14 | **14** | grow with new rules |
| `Funcs.register` sites | ~59 | **59** | stable catalog (`types/funcs.lua`) |
| `require("bridge` sites | — | **194** | **0** (Phase 11) |

### Step 0 (2026-09-12)

- ✅ `test_save_roundtrip` — fixed via `tests/helpers/save_fs.lua` (in-memory `love.filesystem` overlay; save dir is outside workspace in sandboxed runs).
- ✅ Production `G.` reads — **0** (prior grep hit was a comment in `packages/jumbalaya_core/init.lua`; reworded).

### Phase 10a-1 `round/` (2026-09-12)

- `normalize_saved_word_round` + `clear_if_inactive_hand` moved to `jumbalaya_core` (+2 `test_core_*` cases).
- `word_game/model/round/init.lua` slimmed to dispatch + presentation wiring.
- Run analyzer schema consolidated in `types/store.lua`.

---

## Refresh commands

Run from repo root:

```sh
# Production G reads (tests/devtools exempt)
rg '\bG\.' --glob '*.lua' -g '!tests/**' -g '!devtools/**'

# Legacy FUNCS table reads
rg '\.FUNCS\b' app word_game packages

# CardArea (Phase 10b gate)
rg -c 'CardArea' app word_game bridge packages -g '!tests/**'

# Engine must not depend on app/ (Phase 10c gate)
rg 'require\("app\.' packages/

# Glue layer size (Phase 10a)
rg -l 'glue over' word_game/model

# Callback catalog
rg 'Funcs\.register' app word_game

# Bridge package (Phase 11 gate)
rg 'require\("bridge' --glob '*.lua' -g '!docs/**'

# Tests
love tests
```

---

## Runtime buses (replacement map)

| Legacy (removed) | Current |
|------------------|---------|
| Global `G` | `BridgeRuntime.game()` |
| `G.GAME` direct reads in model | `game_access.get()` / `WORD_GAME.store()` |
| `G.FUNCS.name(...)` | `Funcs.dispatch("name", ...)` |
| `G.FUNCS` table on Game | `bridge/funcs_registry.lua` module table |
| `types/g_funcs.lua` | `types/funcs.lua` |

---

## CI gate tests

Must pass on every PR. Full list: [testing.md](testing.md#engine-migration-ci-gate-phase-0).

| Tier | Examples |
|------|----------|
| Core (no boot) | `test_core_jumble_rules.lua`, `test_core_play_evaluate.lua`, … |
| Store / piles | `test_store_sync.lua`, `test_piles.lua`, `test_game_access.lua` |
| Engine / boot | `test_boot_simulation.lua`, `test_table_board.lua` |
| Callback catalog | `test_g_funcs_registry.lua` |
| Gameplay integration | `test_jumble_play_flow.lua`, `test_save_roundtrip.lua` |

---

## Completed coupling removals (Phase 9)

| Coupling | Status |
|----------|--------|
| `G.GAME` reads in `word_game/model/` | ✅ `live_game()` / `game_access` |
| `G.` reads in `word_game/ui/` | ✅ `game_runtime` |
| `G.` reads in `app/`, `board/`, `jumbalaya-engine/` | ✅ `BridgeRuntime.game()` |
| Global `G` singleton (`G = self`) | ✅ `bind_game` only |
| `G.FUNCS` / `types/g_funcs.lua` | ✅ `funcs_registry` + `types/funcs.lua` |
| `LayoutView` / `app/core/ui/` | ✅ `jumbalaya-engine/retained_ui/` |

---

## Remaining coupling (Phase 10)

| Coupling | Where | Target PR |
|----------|-------|-----------|
| Live `Card` / `CardArea` nodes | `word_game/ui/cardarea/`, deck dealing | 10b |
| `pile_sync` dual-write | `bridge/pile_sync.lua` | 10b |
| `app/core/scene` imported by engine | — | **0** (10c: `jumbalaya-engine.scene`) |
| `store_sync.legacy_mirror_*` / `sync_from_g` | — | **removed** (10d) |
| Glue modules (rules already in core) | `word_game/model/*` | 10a |
| `Game.GAME` + store parallel reads | Various glue | 10d |
| Test `mock_env` `_G.G` stub | `tests/helpers/mock_env.lua` | optional cleanup |

---

## Checklist for Phase 10 PRs

- [ ] `love tests` passes
- [ ] Grep deltas recorded in PR description
- [ ] New rules have `test_core_*` coverage
- [ ] No new glue-only rule logic in `word_game/model/`
- [ ] Manual smoke for touched screens (see engine-migration.md §7)
