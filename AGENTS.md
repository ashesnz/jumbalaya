# Agent guide — Jumbalaya

Instructions for AI coding agents working in this repository.

## What this project is

Roguelike **jumble** word game on Love2D/Lua. Active loop: fill **pattern puzzles** from a 7-card hand, bank score × multiplier, clear 24 stages (8 sets × 3 hands). Timeline fuse → tokens; between hands → The Trade marketplace.

**Authoritative docs:** `docs/code-organization.md`, `docs/gameplay.md`, `docs/testing.md`

## Repository layout

```text
app/                     Bootstrap, lifecycle, input, persistence, engine (app/core/)
  bootstrap/             engine_boot.lua + game_boot.lua (loaded by bootstrap.lua)
  startup/               profile, window, dealing, assets, menu_boot
  callbacks/             App-level G.FUNCS (settings, window, run lifecycle)
word_game/
  config/                Static tuning (boot/, layout/, visuals/, gameplay/, perks/, jumble/)
  model/                 Gameplay rules and state (no root-level modules)
    game/                Game class + globals.lua (G singleton)
    run/                 Run state, scope, mode, match end, input lock
    round/               Set/hand progression
    trade/               Marketplace model
    jumble/              Puzzle mode (slots, validation, bonus_stack, placement_word)
    jumble_play/         Play evaluation and hand-clear orchestration
    cards/               Card domain and deck/
    perks/               Perk registry and effects
    feedback/            Model→UI attention text queue
    meta/                Profile/card discovery side effects
  board/                 Jumble pattern row — placement/, jumble/, bonus/ subpackages
  ui/                    TABLE_BOARD presentation, layouts, controls, overlays
devtools/                Development-only tools (stage jump, word hints)
dictionary/              Offline word validation
tests/                   Headless suite — `love tests`
_tools/                  Python asset pipelines (not runtime) — do not edit for gameplay
resources/               Assets, shaders, sounds, fonts
AlphaCardsBackup/        Legacy card-engine reference — do not edit
```

## Dependency rules

- `word_game/ui/` → `app/core/` — **never** reverse
- `word_game/board/` — snap/geometry only; no UI imports at require time (fixed-letter overlay wired from `ui/table/board.lua`)
- Cross-package access: use `WORD_GAME` (domain, `word_game/init.lua`) and `WORD_GAME_UI` (presentation, `word_game/ui/facade/exports.lua`). Inside `word_game/model/`, hoist sibling requires to module scope; use `jumble/bonus_return` when model code must return bonus cards to the gutter.
- **Live state stays on `G`:** `G.GAME` (run snapshot) and `G.FUNCS` (UI callbacks by string) are the runtime bus. Facades are the cross-package API — do not add unowned `G.GAME` fields; declare owners in `types/game.lua`. `G.FUNCS` names stay in `types/g_funcs.lua`.
- Config = data; model = rules/state; ui = presentation — keep separated
- Bootstrap load order lives in `app/bootstrap.lua` only; globals (`G`, `Card`, `LayoutView`) exist after boot
- Model requests layout via `Layout.request_refresh()` / `Presentation.emit` — not UI modules or `G.FUNCS`. Presentation contract: `types/presentation.lua` (one handler per event, `on` overwrites, emit is notify-not-query).

## Active vs legacy

**Jumble mode** is the player experience (`word_game/model/jumble/`, `word_game/model/jumble_play/`). Legacy AP/plays/discards code may remain but is **not active** — do not extend it unless asked.

Removed / renamed (do not reintroduce):

- **Vault** terminology → use **sidebar** (`word_game/ui/sidebar/`)
- Character portraits / `player_host` → removed; table input is `WORD_GAME_UI.TableInput`
- Edition/seal/achievement UI → removed (gold seal shader kept for boss-word bonus cards)

## Key packages

### `WORD_GAME` domain facade (`word_game/init.lua`)

| Export | Role |
|--------|------|
| `Jumble` / `Play` | Puzzle state and play orchestration (`Jumble.PlacementWord`, `Play.Rules`, …) |
| `PlacementWord` / `JumbleRules` | Placement preview and pure scoring rules |
| `Run` / `Busy` / `InputLock` | Run lifecycle and table-busy flags |
| `Board` | `PlacementTable`, `Config`, `Snap`, `JumbleGeometry`, `BonusGutter` |
| `BonusStack` | Bonus gutter model state |
| `VoucherDiscard` | Discard-bin allowance rules (`model/perks/voucher_discard`) |
| `Match` | `end_run()` — game-over from sidebar End Run |

### `WORD_GAME_UI` presentation facade (`word_game/ui/facade/exports.lua`)

| Export | Role |
|--------|------|
| `Layout` | TABLE_BOARD geometry (`layout/felt`, `sidebar/layout`, `layout/placement`) |
| `Sidebar` / `SidebarStageButton` | Right-hand HUD and End Run / Next button |
| `TableBoard` | TABLE_BOARD update/draw coordinator |
| `TimelineTimer` / `ScoreBanner` | Fuse bar and score HUD |
| `TableControls` / `PlayHoldRedraw` | Play + shuffle/remove buttons, hold-to-redraw |
| `TradeUI` / `PerkStamp` / `EndMatch` | Overlays |
| `TableInput` / `TableDeck` | Card input refresh and sidebar deck art |
| `BonusStackUI` | Bonus gutter presentation |

Prefer `WORD_GAME.*` / `WORD_GAME_UI.*` across packages instead of deep requires.

### UI package layout (`word_game/ui/`)

There are **no modules at `word_game/ui/` root** — use subpackage paths only:

| Package | Key modules |
|---------|-------------|
| `util/` | `colour`, `localize`, `number_format`, `roll` |
| `facade/` | Cross-package imports for UI (model/board/app) — use instead of deep `word_game.model.*` requires |
| `cards/` | `tooltip`, `popups`, `visuals`, `ui`, `letter_faces`, `inspect` |
| `table/` | `board`, `deck`, `input`, `dealt_hand`, `controls/`, `token_reward`, `jumble_fixed_letters` |
| `feedback/` | `word_feedback`, `float_up_text`, `confetti`, `comic_burst`, `modifier_feedback` |
| `tutorial/` | `first_play`, `character_speech`, `hand_clear_focus` |
| `play_effects/` | `resolution`, `card_fly_off`, play cinematics |
| `sidebar/` | right-hand HUD (see below) |
| `layout/`, `score_banner/`, `perks/`, `trade/`, `menu/`, `overlays/`, `widgets/`, `callbacks/`, `cardarea/` | as named |

### Sidebar package (`word_game/ui/sidebar/`)

Canonical name for the right-hand HUD column. Do not use "vault" in new code.

```text
sidebar/
  init.lua           Lifecycle: ensure, destroy, refresh, install
  hud_definition.lua HUD tree + relayout
  layout.lua         Column geometry: sidebar_rect, deck_rect, update_sidebar_attach
  stage_button.lua   End Run / Next button animation
  funcs.lua          G.FUNCS: ensure_table_board_sidebar, end_run_from_sidebar
  callbacks.lua      Thin install wrapper
```

Globals: `G.SIDEBAR_HUD`, `G.SIDEBAR_ATTACH`. Layout helpers are re-exported on `WORD_GAME_UI.Layout` (`sidebar_rect`, `sidebar_height`, etc.). `Sidebar.sync_visibility()` shows/hides the HUD column; play/shuffle buttons sync via `WORD_GAME_UI.TableControls.sync()` (not the sidebar API).

### Play resolution split

| Layer | Module | Role |
|-------|--------|------|
| Model | `jumble_play/jumble.lua` | `play_jumble_word()` → result only |
| UI | `play_effects/resolution.lua` | `resolve(Play)` → effects, banners |
| UI | `play_effects/hand_clear.lua` | Hand-clear cinematics; wired from `app/bootstrap/game_boot.lua` |
| UI | `table/controls/placement.lua` | Play button entry point |

Tests that need rules only call `play_jumble_word`; tests that need full FX call `play_effects/resolution.resolve`.

## Lua conventions

- Dot paths from repo root: `require "word_game.ui.sidebar.init"`
- Package folders use `init.lua`; most modules `local M = {}` … `return M`
- Files/dirs/locals: `snake_case`; classes/globals: `PascalCase`
- UI binds `G.FUNCS.*` by string — move implementations, not registration names when refactoring
- Class chain: `Object → Node → EaseNode/Moveable → Sprite, LayoutView, Card, CardArea`
- `Card` model class loads in `app/bootstrap/game_boot.lua`; presentation mixins install via `word_game/ui/cards/bind.lua` (tests: `mock_env.ensure_card_class()`)

## Dev flags

`SKIP_TUTORIAL` — set in shell or `.env` to skip first-play tutorial (`word_game/config/runtime_options.lua`).

## Verification

After logic changes:

```sh
love tests
```

After structural refactors:

```sh
emmylua_check . --severity warn
```

Minimize diff scope; match existing naming and patterns. Startup success alone does not verify jumble transitions, hold-to-redraw, token fly, or marketplace purchase — smoke-test those when touching UI flow.

## Do not hand-edit

- `dictionary/words_set.lua`
- Regenerated `deck_face_colors.lua`
- Binary assets — use `_tools/` scripts

## Commits and PRs

Only create git commits or PRs when explicitly asked. Do not force-push to main.
