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

## `mock_env` recipes

Copy these patterns from existing tests rather than re-stubbing globals ad hoc.

### Reset a suite (default)

```lua
local mock_env = require("tests.helpers.mock_env")

T.describe("my feature", function()
    mock_env.reset_game()
    -- store snapshot via mock_env.game_state(); G.pattern_row, WORD_GAME.Deck seeded
end)
```

Use `mock_env.patch_game({ ... })` for top-level store fields and `mock_env.mutate_game(fn)` for nested edits.

### Publish custom run state (deal a hand, set target, jumble fields)

```lua
mock_env.reset_game()
mock_env.publish_game({
    word_score_animating = false,
    hand_redraw_animating = false,
    seed_streams = { seed = "TEST", hashed_seed = 0 },
    word_round = {
        set = 1,
        hand_index = 1,
        target = 25,
        mode = "jumble",
        jumble = { total_score = 0, puzzle_points = 0, puzzle_multi = 1.0, slots = {} },
    },
})
```

Use `mock_env.patch_game` / `mock_env.mutate_game` for mid-test edits — do not mutate a cached snapshot across dispatches.

### Stub sidebar / table controls

```lua
WORD_GAME_UI.TableControls = {
    play_button_uie = function() return mock_btn end,
    sync = function() end,
    placement_has_cards = function() return false end,
}
WORD_GAME_UI.TradeUI = { is_open = function() return false end }
WORD_GAME_UI.Sidebar = { sync_visibility = function() end, draw = function() end }
```

See `test_play_hold_redraw.lua`, `test_classic_run_mode.lua`.

### Simulate play (model only vs full FX)

```lua
-- Rules only (no cinematics)
local Play = require("word_game.model.jumble_play")
local result = Play.play_jumble_word()

-- Full resolution (banners, fly-off, hand clear)
local resolution = require("word_game.ui.play_effects.resolution")
resolution.resolve(Play, { instant = true })
```

### Presentation bus / score banner

```lua
mock_env.install_presentation({
    ScoreBanner = {
        snap_to_actual = function() snaps = snaps + 1 end,
        sync_points_to_get_preview = function(enabled) preview = enabled end,
    },
})
require("word_game.model.presentation").emit("PLAY_RESOLVED", { kind = "word_play", old_score = 0, new_score = 3 })
```

See `test_presentation_flow.lua`.

### Hand-clear wiring (matches boot)

```lua
local Play = mock_env.install_hand_clear() -- installs hand_clear on Play module
-- Play.on_hand_cleared / continue_after_dealer now behave like production
```

### Real Card instances

```lua
mock_env.ensure_card_class()
-- Card, sprites, tooltip mixins loaded — use for drag/snap tests
```

### Engine globals without full game reset

```lua
mock_env.ensure_engine_globals() -- Sprite, Node, AnimNode, colour helpers
```

### API quick reference

| Function | Use when |
|----------|----------|
| `reset_game()` | Start of every `describe` — preferred default |
| `game_state()` | Read authoritative store snapshot |
| `patch_game(fields)` | Shallow-merge top-level run fields |
| `mutate_game(fn)` | Copy-on-write nested test fixtures |
| `publish_game(table)` | Bind store from a snapshot |
| `clear_store_piles()` | Host-only pile tests; empty `store.piles` |
| `install_presentation(overrides)` | Stub `WORD_GAME_UI` + wire `presentation/install` |
| `install_hand_clear(play_module)` | Hand-clear / marketplace transition tests |
| `ensure_card_class()` | Tests that construct or draw `Card` |
| `ensure_engine_globals()` | Low-level scene-graph tests without full run state |
| `setup()` | Rare; `reset_game()` calls this — use only for custom shells |
| `teardown_boot_pollution()` | Alias for `reset_game()` |

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
| **Store / access** | `test_store_ops.lua`, `test_store_stale_ref.lua`, `test_game_access.lua`, `test_piles.lua` | Store binding, `game_access`, pile hosts, stale-ref guards |
| **UI / table** | `test_table_board.lua`, `test_sidebar_stage_button.lua`, `test_timeline_timer.lua`, … | HUD, fuse, table rendering |
| **Persistence** | `test_save_roundtrip.lua` | Save/load contract |
| **Boot / policy** | `test_boot_simulation.lua`, `test_g_funcs_registry.lua`, `test_store_state_catalog.lua`, `test_facade_boundaries.lua`, `test_core_purity.lua`, `test_legacy_shims.lua` | Startup smoke, Funcs/UI bindings, run-state catalog, facade imports, core isolation, proxy-file scan |

## CI

GitHub Actions (`.github/workflows/tests.yml`) runs on every push and PR:

| Job | Tool | Pin |
|-----|------|-----|
| `love-tests` | LÖVE AppImage **11.5** | `LOVE_VERSION` in workflow — not distro `apt` packages |
| `emmylua-check` | `emmylua_check` **0.25.1** | `EMMYLUA_CHECK_VERSION` in workflow |

CI runs `emmylua_check . --severity error` (blocks on analyzer errors). Locally, install/run via:

```sh
love tests
_tools/run_emmylua_check.sh warn
```

The helper installs `emmylua_check` **0.25.1** (same pin as CI) when missing and adds `~/.cargo/bin` to `PATH`.

Smoke-test title screen, score banner animations, and token fly in-game when touching those UI flows — those paths no longer have dedicated unit tests.
