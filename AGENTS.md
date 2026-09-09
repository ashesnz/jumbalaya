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
AlphaCardsBackup/        Legacy Balatro reference — do not edit
```

## Dependency rules

- `word_game/ui/` → `app/core/` — **never** reverse
- `word_game/board/` — snap/geometry only; no UI imports at require time (fixed-letter overlay wired from `ui/table/board.lua`)
- Cross-package access: use `WORD_GAME` facade (`word_game/init.lua`), not deep `require` from `app/` or `tests/`. Inside `word_game/model/`, hoist sibling requires to module scope; use `jumble/bonus_return` when model code must return bonus cards to the gutter.
- Config = data; model = rules/state; ui = presentation — keep separated
- Bootstrap load order lives in `app/bootstrap.lua` only; globals (`G`, `Card`, `LayoutView`) exist after boot
- Model requests layout via `WORD_GAME.Layout.request_refresh()` — not direct geometry from model code

## Active vs legacy

**Jumble mode** is the player experience (`word_game/model/jumble/`, `word_game/model/jumble_play/`). Legacy AP/plays/discards code may remain but is **not active** — do not extend it unless asked.

Removed / renamed (do not reintroduce):

- **Vault** terminology → use **sidebar** (`word_game/ui/sidebar/`)
- Character portraits / `player_host` → removed; table input is `WORD_GAME.TableInput`
- Edition/seal/achievement UI → removed (gold seal shader kept for boss-word bonus cards)

## Key packages

### `WORD_GAME` facade exports (`word_game/init.lua`)

| Export | Role |
|--------|------|
| `Jumble` / `Play` | Puzzle state and play orchestration (`Jumble.PlacementWord`, `Play.Rules`, …) |
| `PlacementWord` / `JumbleRules` | Placement preview and pure scoring rules |
| `Run` | Run lifecycle facade (`Run.State`, `Run.Mode`, `Run.Scope`, …) |
| `Board` | `PlacementTable`, `Config`, `Snap`, `JumbleGeometry`, `BonusGutter` |
| `Layout` | TABLE_BOARD geometry (`layout/felt`, `sidebar/layout`, `layout/placement`) |
| `Sidebar` | Right-hand HUD (stamps, deck, cards-left, End Run) |
| `SidebarStageButton` | Classic End Run / Next button |
| `TableBoard` | TABLE_BOARD update/draw coordinator |
| `VoucherDiscard` | Sidebar voucher discard |
| `TimelineTimer` | 60s fuse / classic score slider |
| `HandShuffle` / `PlayHoldRedraw` | Shuffle + Play buttons, hold-to-redraw |
| `TradeUI` / `PerkStamp` | Marketplace and perk stamp overlays |
| `TableInput` | Card input refresh on the table board |
| `Match` | `end_run()` — game-over from sidebar End Run |

Prefer `WORD_GAME.*` across packages instead of deep requires.

### UI package layout (`word_game/ui/`)

There are **no modules at `word_game/ui/` root** — use subpackage paths only:

| Package | Key modules |
|---------|-------------|
| `util/` | `colour`, `localize`, `number_format`, `roll` |
| `facade/` | Cross-package imports for UI (model/board/app) — use instead of deep `word_game.model.*` requires |
| `cards/` | `tooltip`, `popups`, `visuals`, `ui`, `letter_faces`, `inspect` |
| `table/` | `board`, `deck`, `input`, `dealt_hand`, `placement_controls`, `stage_label`, `token_reward`, `jumble_fixed_letters` |
| `feedback/` | `word_feedback`, `float_up_text`, `confetti`, `comic_burst`, `modifier_feedback` |
| `tutorial/` | `first_play`, `character_speech`, `hand_clear_focus` |
| `play_effects/` | `resolution`, `card_fly_off`, play cinematics |
| `hand_shuffle/` | shuffle/play buttons, `play_hold_redraw` |
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

Globals: `G.SIDEBAR_HUD`, `G.SIDEBAR_ATTACH`. Layout helpers are re-exported on `WORD_GAME.Layout` (`sidebar_rect`, `sidebar_height`, etc.).

### Play resolution split

| Layer | Module | Role |
|-------|--------|------|
| Model | `jumble_play/jumble.lua` | `play_jumble_word()` → result only |
| UI | `play_effects/resolution.lua` | `resolve(Play)` → effects, banners |
| UI | `play_effects/hand_clear.lua` | Hand-clear cinematics; calls model `prepare_hand_clear` / `resolve_after_clear` |
| UI | `table/placement_controls.lua` | Play button entry point |

Tests that need rules only call `play_jumble_word`; tests that need full FX call `play_effects/resolution.resolve`.

## Lua conventions

- Dot paths from repo root: `require "word_game.ui.sidebar.init"`
- Package folders use `init.lua`; most modules `local M = {}` … `return M`
- Files/dirs/locals: `snake_case`; classes/globals: `PascalCase`
- UI binds `G.FUNCS.*` by string — move implementations, not registration names when refactoring
- Class chain: `Object → Node → EaseNode/Moveable → Sprite, LayoutView, Card, CardArea`

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
