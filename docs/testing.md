# Testing in Jumbalaya

Jumbalaya includes a headless unit testing framework built on Love2D.

## Running Unit Tests

Run the test suite directly from the terminal:

```sh
love tests
```

The test runner runs headlessly (without opening a display window) and outputs formatted test results to the terminal with standard exit codes (`0` for all passed, `1` for failures).

## Test Directory Structure

```text
tests/
├── conf.lua                  # Headless Love2D config (disables window/audio/graphics)
├── main.lua                  # Entry point for `love tests`
├── runner.lua                # Auto-discovers and runs tests/unit/test_*.lua
├── framework.lua             # Test assertions (`describe`, `it`, `assert_equal`, etc.)
├── helpers/
│   ├── mock_env.lua          # Shared game globals and mock environment
│   ├── g_funcs_audit.lua     # Funcs.register catalog static audit
│   └── core_env.lua          # jumbalaya_core package.path bootstrap
└── unit/
    └── test_*.lua            # One file per feature area (auto-discovered)
```

`tests/runner.lua` discovers every `tests/unit/test_*.lua` file via `love.filesystem.getDirectoryItems("unit")` (portable; no shell `ls`) — no manual registration list.

## Shared test helpers

`tests/helpers/mock_env.lua` provides:

- `ensure_engine_globals()` — loads real `Card`, `Sprite`, `AnimNode`, etc.
- `reset_game()` — preferred per-suite reset: binds `BridgeRuntime.game()`, seeds run state, layout stubs, bonus-stack/fly-off state
- `setup()` — low-level globals only; called by `reset_game()`, avoid at describe level unless booting a custom shell (e.g. screen-wipe tests)
- `install_hand_clear(play_module)` — mirrors `game_boot` wiring for `Play.on_hand_cleared` / `continue_after_dealer`
- `teardown_boot_pollution()` — alias for `reset_game()`

Prefer `mock_env.reset_game()` at the top of a `describe` block. Tests that call `Game()` should use `BridgeRuntime.game()` (or the returned instance), not a stale global `G` stub. When mocking draw piles, keep `letter_inventory` and `draw_pile.cards` as **separate tables** (production does not alias them).

**Core rule tests** (`test_core_*.lua`) call `jumbalaya_core` directly via `tests/helpers/core_env.lua` — no `mock_env.ensure_engine_globals()` needed.

## Adding New Tests

1. Create `tests/unit/test_<name>.lua`.
2. Use the harness:

   ```lua
   local T = require("tests.framework")
   local mock_env = require("tests.helpers.mock_env")

   T.describe("My Feature Suite", function()
       mock_env.reset_game()

       T.it("performs expected behavior", function()
           T.assert_equal(1 + 1, 2)
       end)
   end)
   ```

3. Run `love tests` to verify.

## Key test files (jumble pivot)

| File | Covers |
|------|--------|
| `test_jumble_patterns.lua` | Pattern validation, slots, geometry |
| `test_jumble_scoring.lua` | Scoring, odometer, targets |
| `test_jumble_play_flow.lua` | Play flow, marketplace, stage files |
| `test_table_discard.lua` | Sidebar discard bin, `max_fills()`, game-over |
| `test_sidebar_stage_button.lua` | Sidebar End Run / Next button |
| `test_timeline_timer.lua` | Fuse bar |
| `test_save_roundtrip.lua` | Card/area save, disk round-trip, jumble hand restore fixture |
| `test_voucher_tokens.lua` | Perk stamp rolls |
| `test_hand_shuffle.lua` | Shuffle/play buttons |
| `test_play_hold_redraw.lua` | Hold-to-redraw |
| `test_layout.lua` | Sidebar HUD geometry and fixed width |

## Engine migration CI gate (Phase 0+)

These tests must pass on every PR while migrating off the Balatro engine pattern. See [engine-migration.md](engine-migration.md).

| File | Covers |
|------|--------|
| `test_jumble_patterns.lua` | Core rule tests (headless) |
| `test_jumble_scoring.lua` | Scoring rules |
| `test_jumble_play_flow.lua` | Play orchestration |
| `test_timeline_timer.lua` | Fuse model |
| `test_voucher_tokens.lua` | Perk economy |
| `test_save_roundtrip.lua` | Persistence contract |
| `test_store_sync.lua` | `bridge/store_sync.lua` shim |
| `test_phase2_store_boot.lua` | Phase 2 store boot, dispatch dual-write, run binding |
| `test_phase3_engine_services.lua` | Phase 3 engine context, adapters, and boot wiring |
| `test_phase4_action_dispatch.lua` | Phase 4 Funcs → InputService action dispatch |
| `test_phase5_1_cards_piles.lua` | Phase 5.1 LetterCard data, pile reducers, engine views |
| `test_phase5_2_table_areas.lua` | Phase 5.2 TableAreas selectors and save aliases |
| `test_phase5_3_snap.lua` | Phase 5.3 Snap placement `MOVE_CARD` dispatch |
| `test_phase5_4_persistence.lua` | Phase 5.4 store-based run save/restore |
| `test_phase5_pile_sync.lua` | Phase 5 pile dual-write bridge |
| `test_phase6_1_table_board.lua` | Phase 6.1 TableBoardView store subscription and pile rendering |
| `test_phase6_2_fx_subscribers.lua` | Phase 6.2 EventBus, FX subscribers, presentation hooks |
| `test_phase6_3_uibox_retirement.lua` | Phase 6.3 `G.LIVE.UIBOX` retirement and store-backed TABLE_BOARD draw |
| `test_phase7_bootstrap.lua` | Phase 7 slim bootstrap modules and engine_adapter wiring |
| `test_phase7_store_authority.lua` | Phase 7 WORD_GAME owns store/engine; G._store/_engine absent |
| `test_phase8_layoutview_retirement.lua` | Phase 8 PR-8 retained UI in `jumbalaya-engine` |
| `test_phase9_runtime_shell.lua` | Phase 9 `bridge/runtime` game shell + session layer |
| `test_phase9_no_g_singleton.lua` | Phase 9 `Game()` does not assign global `G` |
| `test_core_store_dispatch.lua` | `jumbalaya_core` store reducers without boot |
| `test_g_funcs_registry.lua` | `types/funcs.lua` catalog freeze |
| `test_core_jumble_rules.lua` | `jumbalaya_core` scoring rules without boot |
| `test_core_jumble_patterns.lua` | `jumbalaya_core` pattern/slot validation without `G` |
| `test_core_hand.lua` | `jumbalaya_core` hand lifecycle without `G` |
| `test_core_round.lua` | `jumbalaya_core` round reducers without `G` |
| `test_core_dictionary_cards.lua` | `jumbalaya_core` dictionary card letter helpers without `G` |
| `test_core_cards_identity.lua` | `jumbalaya_core` card face keys and letter-card detection without `G` |
| `test_core_cards_letter_modifiers.lua` | `jumbalaya_core` per-letter modifier data without `G` |
| `test_core_cards_playability.lua` | `jumbalaya_core` deck playability helpers without `G` |
| `test_core_cards_deck_config.lua` | `jumbalaya_core` starting deck and trade letter weights without `G` |
| `test_core_cards_letter_card.lua` | `jumbalaya_core` letter card data, sort, and inventory filters without `G` |
| `test_core_hand_size.lua` | `jumbalaya_core` hand size from base + perks without `G` |
| `test_core_perk_effects.lua` | `jumbalaya_core` perk word/bank effects without `G` |
| `test_core_play_evaluate.lua` | `jumbalaya_core` play evaluation (bank + word play) without `G` |

## CI

GitHub Actions (`.github/workflows/tests.yml`) runs on every push and PR:

| Job | Tool | Pin |
|-----|------|-----|
| `love-tests` | LÖVE AppImage **11.5** | `LOVE_VERSION` in workflow — not distro `apt` packages |
| `emmylua-check` | `emmylua_check` **0.25.1** | `EMMYLUA_CHECK_VERSION` in workflow |

CI runs `emmylua_check . --severity error` (blocks on analyzer errors). Locally, use `--severity warn` before structural refactors:

```sh
love tests
emmylua_check . --severity warn
```

Headless coverage also includes `test_token_reward_fly.lua`, `test_marketplace_purchase_deal.lua`, and an end-to-end hold-redraw case in `test_play_hold_redraw.lua`. Smoke-test full animated flows in-game when touching UI flow.
