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

`tests/runner.lua` discovers every `tests/unit/test_*.lua` file alphabetically — no manual registration list.

## Shared test helpers

`tests/helpers/mock_env.lua` provides:

- `ensure_engine_globals()` — loads real `Card`, `Sprite`, `AnimNode`, etc.
- `setup()` / `reset_game()` — minimal `G.GAME`, `G.placement_table`, and layout stubs
- `teardown_boot_pollution()` — resets globals between suites that boot the full app

Prefer `mock_env.reset_game()` at the top of a `describe` block. When mocking `G.deck`, keep `G.playing_cards` and `G.deck.cards` as **separate tables** (production does not alias them).

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
| `test_table_discard.lua` | Discard bin, `max_fills()`, game-over |
| `test_timeline_timer.lua` | Fuse bar |
| `test_voucher_tokens.lua` | Perk stamp rolls |
| `test_hand_shuffle.lua` | Shuffle/play buttons |
| `test_play_hold_redraw.lua` | Hold-to-redraw |

## Verification after refactors

```sh
love tests
emmylua_check . --severity warn
```

Startup success alone does not verify jumble puzzle transitions, hold-to-redraw, token fly, or marketplace purchase — smoke-test those manually when touching UI flow.
