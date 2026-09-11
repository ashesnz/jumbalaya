# Testing in Jumbalaya

Jumbalaya includes a headless unit testing framework built on Love2D.

## Running Unit Tests

Run the test suite directly from the terminal:

```sh
love games/jumbalaya tests
```

Root shim: `love tests` or `love . tests` (same suite).

The test runner runs headlessly (without opening a display window) and outputs formatted test results to the terminal with standard exit codes (`0` for all passed, `1` for failures).

## Test Directory Structure

```text
games/jumbalaya/tests/
├── conf.lua                  # Headless Love2D config (disables window/audio/graphics)
├── main.lua                  # Legacy entry (use `love games/jumbalaya tests`)
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
| `test_core_jumble_patterns.lua` | Pattern validation, slots (headless) |
| `test_jumble_scoring.lua` | Scoring, odometer, targets |
| `test_jumble_play_flow.lua` | Play flow, marketplace, stage files |
| `test_classic_run_mode.lua` | Classic run loop and stage progression |
| `test_classic_stage_advance_deal.lua` | Next → marketplace → deal on stage advance |
| `test_table_discard.lua` | Sidebar discard bin, `max_fills()`, game-over |
| `test_sidebar_stage_button.lua` | Sidebar End Run / Next button |
| `test_timeline_timer.lua` | Fuse bar |
| `test_save_roundtrip.lua` | Save/load round-trip, jumble hand restore |
| `test_play_hold_redraw.lua` | Hold-to-redraw |
| `test_play_resolution.lua` | Play cinematics and score resolution |

## CI gate (representative)

These tests must pass on every PR. See [code-organization.md](code-organization.md) for package boundaries and freeze policy.

| Tier | Files | Role |
|------|-------|------|
| **Core rules** | `test_core_*.lua` | `jumbalaya_core` headless — no Love2D boot |
| **Gameplay** | `test_jumble_*.lua`, `test_play_resolution.lua`, `test_classic_run_mode.lua`, … | Jumble loop, scoring, marketplace |
| **Store / access** | `test_store_sync.lua`, `test_game_access.lua`, `test_piles.lua` | Store binding, `game_access`, pile hosts |
| **UI / table** | `test_table_board.lua`, `test_sidebar_stage_button.lua`, `test_timeline_timer.lua`, … | HUD, fuse, table rendering |
| **Persistence** | `test_save_roundtrip.lua` | Save/load contract |
| **Boot** | `test_boot_simulation.lua`, `test_g_funcs_registry.lua` | Startup smoke, Funcs catalog freeze |

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

Smoke-test title screen, score banner animations, and token fly in-game when touching those UI flows — those paths no longer have dedicated unit tests.
