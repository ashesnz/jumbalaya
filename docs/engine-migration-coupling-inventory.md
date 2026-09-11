# Engine migration — coupling inventory (Phase 0)

Baseline captured **2026-09-11**. Re-run the commands in [Refreshing this inventory](#refreshing-this-inventory) before Phase 1.

Related: [engine-migration.md](engine-migration.md) (full roadmap), [code-organization.md](code-organization.md) (freeze policy).

---

## Summary

| Coupling | Total refs | Primary locations | Migration phase |
|----------|------------|-------------------|-----------------|
| `G.GAME` in model | 103 | `run/scope.lua`, `round/init.lua`, `jumble/placement_word.lua` | Phase 1–2 (store) |
| `G.` in model (all) | 489 | `cards/deck/jumble.lua`, `run/scope.lua`, `cards/deck/*` | Phase 1–5 |
| `G.FUNCS` in production Lua | 134 | `callbacks/overlays.lua`, `callbacks/window.lua`, `ui/callbacks/*` | Phase 4 |
| `G.` in board | 48 | `placement/snap.lua` (26), `bonus/gutter.lua` (12) | Phase 5 |
| `G.FUNCS` catalog entries | 58 | `types/g_funcs.lua` | Phase 4 |
| `G.FUNCS` static registrations | 55 | `app/callbacks/*`, `word_game/ui/callbacks/*`, `sidebar/funcs.lua` | Phase 4 |

`dictionary/` has **zero** `G` references — ready for `jumbalaya-core` as-is.

---

## Test baseline (Phase 0)

| Check | Result |
|-------|--------|
| `love tests` | **372 passed** (0 failed) |
| `emmylua_check . --severity warn` | Run locally (CI uses error severity) |

### Migration CI gate tests

These suites must stay green through every migration phase:

| File | Covers |
|------|--------|
| `test_jumble_patterns.lua` | Pattern validation, slots, geometry |
| `test_jumble_scoring.lua` | Scoring, odometer, targets |
| `test_jumble_play_flow.lua` | Play flow, marketplace, stage files |
| `test_timeline_timer.lua` | Fuse bar |
| `test_voucher_tokens.lua` | Perk stamp rolls |
| `test_save_roundtrip.lua` | Save/load, jumble hand restore |
| `test_store_sync.lua` | Store ↔ `G.GAME` shim contract |
| `test_g_funcs_registry.lua` | `G.FUNCS` catalog freeze |

---

## `G.GAME` by model module

Grouped by `types/game.lua` field owners. Counts are `G.GAME` references only.

| Module | `G.GAME` refs | Owns / touches |
|--------|---------------|----------------|
| `run/scope.lua` | 10 | `run_mode`, `run_state`, scope transitions |
| `round/init.lua` | 10 | `word_round` lifecycle |
| `jumble/placement_word.lua` | 8 | `placement_word`, `placement_word_valid` |
| `run/state.lua` | 7 | `run_state` (tokens, perks) |
| `perks/voucher_discard.lua` | 7 | `voucher_discards_used`, `discard_bin_count` |
| `run/busy.lua` | 6 | `trade_ui_busy`, `token_reward_busy`, … |
| `cards/deck/jumble.lua` | 6 | deck dealing + `word_round.jumble` |
| `run/match.lua` | 5 | match end / surrender |
| `jumble/hand.lua` | 5 | puzzle hand start |
| `perks/registry.lua` | 4 | `selected_perk` |
| `jumble/puzzle_spec.lua` | 4 | puzzle spec on `word_round.jumble` |
| `jumble_play/jumble_rules.lua` | 3 | play evaluation reads |
| `jumble_play/hand.lua` | 3 | hand-clear model path |
| `jumble/validation.lua` | 3 | slot validation |
| `trade/init.lua` | 2 | marketplace state |
| `run/timeline.lua` | 2 | `timeline_*` fuse fields |
| `run/mode.lua` | 2 | `run_mode` |
| `run/input_lock.lua` | 2 | animation lock reads |
| `persistence/run_save.lua` | 2 | save snapshot |
| `jumble_play/jumble.lua` | 2 | play / end hand |
| `game/run.lua` | 2 | run bootstrap |
| `cards/deck/dealing.lua` | 2 | deal paths |
| `cards/deck/boss_hand.lua` | 2 | boss word staging |
| `persistence/progress.lua` | 1 | profile progress gate |
| `perks/effects.lua` | 1 | perk hooks |
| `jumble_play/opening_deal.lua` | 1 | timeout re-deal |
| `cards/deck/lifecycle.lua` | 1 | `starting_deck_size` |

---

## Scene globals (`G` outside `G.GAME`)

Live `CardArea` / table wiring on `G` (migrate in Phase 5):

| Global | Role | Accessor |
|--------|------|----------|
| `G.dealt_letters` | Dealt hand row | `word_game/model/table_areas.lua` |
| `G.draw_pile` | Draw stack | `table_areas.draw_pile()` |
| `G.recycle_stash` | Fly-off / recycle | `table_areas.recycle_stash()` |
| `G.pattern_row` | Pattern row controller | `table_areas.pattern_row()` |
| `G.SIDEBAR_HUD` | Right-hand HUD UIBox | `word_game/ui/sidebar/` |
| `G.SIDEBAR_ATTACH` | Sidebar layout attach node | `sidebar/layout.lua` |
| `G.LETTERS` | Letter face registry | `model/cards/registry.lua` |
| `G.letter_inventory` | Run letter card pool | `model/cards/deck/` |

---

## `G.FUNCS` by area

| Area | Module | Refs | Callbacks registered |
|------|--------|------|----------------------|
| Overlays | `word_game/ui/callbacks/overlays.lua` | 15 | `open_options`, `open_settings`, `quit`, … |
| Window | `app/callbacks/window.lua` | 13 | `change_vsync`, `change_screenmode`, … |
| Text input | `app/callbacks/ui_controls/text_input.lua` | 12 | `text_input`, `key_button`, … |
| Run lifecycle | `app/callbacks/run_lifecycle.lua` | 9 | `begin_run`, `return_to_menu`, … |
| Profile | `app/profile_callbacks.lua` | 7 | `load_profile`, `delete_profile`, … |
| Trade | `word_game/ui/callbacks/trade.lua` | 5 | `trade_pick`, `trade_skip`, … |
| Table controls | `word_game/ui/callbacks/table_controls.lua` | 5 | `play_placement_word`, `shuffle_hand`, … |
| Sidebar | `word_game/ui/sidebar/funcs.lua` | 5 | `end_run_from_sidebar`, `classic_stage_next`, … |
| Screen wipe | `app/screen_wipe.lua` | 6 | `wipe_in`, `wipe_out` |

Full catalog: `types/g_funcs.lua` (58 names). Static audit: `tests/helpers/g_funcs_audit.lua`.

---

## `word_game/board/` coupling

| Module | `G.` refs | Notes |
|--------|-----------|-------|
| `placement/snap.lua` | 26 | Drag snap — highest board coupling |
| `bonus/gutter.lua` | 12 | Bonus stack hit tests |
| `placement/layout.lua` | 6 | Row geometry |
| `placement/config.lua` | 2 | Tunables |
| `placement/table.lua` | 1 | Row host |
| `placement/shimmer.lua` | 1 | Lock-in FX |

Board must stay free of UI imports at load time; Phase 5 replaces `G`/`CardArea` with rect + pile state.

---

## Store shim contract

Module: `bridge/store_sync.lua`

| API | Direction | Use |
|-----|-----------|-----|
| `store_sync.new(initial)` | — | Create store |
| `store_sync.replace(store, state)` | store → `G.GAME` | Full state swap |
| `store_sync.patch(store, patch)` | store → `G.GAME` | Shallow merge |
| `store_sync.sync_to_g(store)` | store → `G.GAME` | Mirror only |
| `store_sync.sync_from_g(store)` | `G.GAME` → store | Boot / test bridge |
| `store_sync.subscribe(store, fn)` | notify | View layer (Phase 2+) |

Tests: `tests/unit/test_store_sync.lua`.

**Not wired at boot yet** — Phase 2 instantiates the store in `game_boot.lua`.

---

## Phase 0 exit criteria

- [x] Coupling inventory documented (this file)
- [x] `bridge/store_sync.lua` shim defined and tested
- [x] `G.FUNCS` catalog freeze enforced by `test_g_funcs_registry.lua`
- [x] Global growth freeze documented in `code-organization.md`
- [x] Migration CI gate tests listed in `testing.md`
- [x] `love tests` baseline green (372 tests)

---

## Refreshing this inventory

```sh
# G.GAME in model (per file)
rg '\bG\.GAME\b' word_game/model --count | sort -t: -k2 -nr

# G.FUNCS in production
rg '\bG\.FUNCS\b' --count --glob '*.lua' | grep -v '^tests/' | grep -v '^docs/'

# Board coupling
rg '\bG\.' word_game/board --count | sort -t: -k2 -nr

# Re-validate catalog
love tests
```

Update the summary table and date when counts change materially.
