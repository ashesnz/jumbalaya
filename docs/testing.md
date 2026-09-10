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
│   └── mock_env.lua          # Shared game globals and mock environment
└── unit/
    └── test_*.lua            # One file per feature area (auto-discovered)
```

`tests/runner.lua` discovers every `tests/unit/test_*.lua` file via `love.filesystem.getDirectoryItems("unit")` (portable; no shell `ls`) — no manual registration list.

## Shared test helpers

`tests/helpers/mock_env.lua` provides:

- `ensure_engine_globals()` — loads real `Card`, `Sprite`, `AnimNode`, etc.
- `reset_game()` — preferred per-suite reset: `G.GAME`, `G.pattern_row`, layout stubs, bonus-stack/fly-off state
- `setup()` — low-level globals only; called by `reset_game()`, avoid at describe level unless booting a custom shell (e.g. screen-wipe tests)
- `install_hand_clear(play_module)` — mirrors `game_boot` wiring for `Play.on_hand_cleared` / `continue_after_dealer`
- `teardown_boot_pollution()` — alias for `reset_game()`

Prefer `mock_env.reset_game()` at the top of a `describe` block. When mocking `G.draw_pile`, keep `G.letter_inventory` and `G.draw_pile.cards` as **separate tables** (production does not alias them).

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
