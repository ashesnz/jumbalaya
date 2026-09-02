# Code organization

Jumbalaya uses a small application shell around the Love2D engine and a separate word-game domain:

- **Engine modules** provide the global-compatible Love2D foundation (`G`, `Card`, `UIBox`, and related classes).
- **Jumbalaya-owned packages** organize gameplay and presentation under `word_game/`.

New code should use the package style. Existing global APIs should only be changed through a dedicated migration so load order and string-based callbacks remain stable.

---

## Directory responsibilities

```text
app/                     Application bootstrap, startup, lifecycle, persistence, and callbacks
  bootstrap/             engine_boot.lua + game_boot.lua (loaded by bootstrap.lua)
  startup/               profile, window, dealing, assets, menu_boot
app/runtime/             Rendering, input, scene graph, UI classes, and shared runtime helpers
word_game/
  board/                 jumble pattern row (placement_table, snap, geometry)
  config/                static tuning: round targets, puzzles, perks, and runtime options
  model/                 gameplay state, card domain, deck, flow, and round rules
    game/                Game class: init, prep_stage, start_run, loop hooks
  ui/                    gameplay presentation, layouts, controls, and UI definitions
    table_board.lua      TABLE_BOARD update/draw coordinator (used from app/loop.lua)
devtools/                development-only tools (stage jump, word hints)
dictionary/              offline word list and playability checks
types/                   analyzer-only EmmyLua declarations
docs/                    player and design documentation (this folder)
```

### UI foundation versus word-game UI

These two UI locations serve different layers and should not be merged:

- `app/runtime/ui.lua` defines the reusable `UIBox` and `UIElement` scene graph. It owns layout measurement, alignment, hit testing, focus, animation hooks, and drawing; it must remain independent of Jumbalaya screens and gameplay.
- `word_game/ui/` defines Jumbalaya presentation such as the HUD, cards, menus, overlays, controls, and board layouts. These modules build `UIBox` definitions and connect them to word-game state.

The dependency direction is `word_game/ui/` → `app/runtime/ui.lua`. Moving the engine classes into `word_game/ui/` would couple the reusable engine layer to the game and would not remove duplicated functionality. New generic UI primitives belong in `app/runtime/`; game-specific UI belongs in `word_game/ui/`.

`app/runtime/text.lua` follows the same boundary. `DynaText` owns measurement, animated letter rendering, scaling, and alignment. Its reads from `G.LANG`, `G.C`, `G.TIMERS`, and `G.I.MOVEABLE` are engine runtime contracts supplied during bootstrap; localization choices, number formatting, and presentation copy remain in `word_game/ui/`.

### Callback ownership

Callbacks are grouped by responsibility under `app/callbacks/` and `word_game/ui/`:

| Area | Module |
|------|--------|
| HUD refresh / rebuild | `word_game/ui/sidebar.lua` via `WORD_GAME.Sidebar` |
| Screen / placement layout | `word_game/ui/layout/` via `WORD_GAME.Layout` or `require "word_game.ui.layout"`; model code requests deferred layout via `Layout.request_refresh()` |
| Play button / placement | `word_game/ui/placement_controls.lua` (`G.FUNCS.play_placement_word`; not on `WORD_GAME` facade) |
| Profile load / delete | `app/profile_callbacks.lua` |
| Settings, text input, overlays, run lifecycle | `app/callbacks/settings.lua` |
| Shared timed effects | `app/callbacks/effects.lua` |
| Card tooltips | `word_game/ui/card_tooltip.lua` |
| Screen wipe transitions | `app/screen_wipe.lua` |

`app/bootstrap.lua` loads callbacks in dependency order and wires `Controller._input_actions` from `app/input_actions.lua` so `app/runtime/controller.lua` does not require application code.

Obsolete collection, challenge, tutorial, promotional, social, and poker-only callbacks are removed with their active UI bindings rather than relocated into Jumbalaya packages.

### Pivot note

The **active player loop** is jumble mode (`word_game/model/jumble/` + `word_game/model/play/jumble.lua` → `play_jumble_word`). The **placement row** serves **pattern slots**, not free-form left-to-right spelling.

---

## Package entry point

`word_game/init.lua` registers the public facade as `WORD_GAME` and loads the domain packages. The facade exports only modules used across packages (`app/`, `tests/`, `devtools/`). Package-internal modules (config tables, card definitions, trade rules, etc.) are loaded via direct `require` inside `word_game/`.

| Export | Role |
|--------|------|
| `Jumble` | Puzzle state, validation, scoring, hand start |
| `Play` | Play-button orchestration: `play_word`, jumble bank/advance, hand clear, trade transition |
| `Round` | Set/hand lifecycle, targets, perk-hand gating |
| `Deck` / `Back` | Dealing; jumble branch in `model/deck/jumble.lua` |
| `Board` | Jumble pattern row (`board/placement_table`, snap, geometry) |
| `TableBoard` | TABLE_BOARD update/draw coordinator |
| `Layout` | TABLE_BOARD geometry (`layout/felt`, `layout/vault`, `layout/placement`) |
| `ScoreBanner` | Jumble chips, multiplier, points-to-get label |
| `TimelineTimer` | 60s fuse HUD |
| `TokenReward` | 1-1 token fly animations |
| `HandShuffle` / `PlayHoldRedraw` | Shuffle + Play buttons, hold-to-redraw |
| `TradeUI` / `PerkStamp` | Marketplace and perk stamp overlays |
| `Sidebar` | Vault HUD (stamps, deck) |
| Hosts / portraits / overlays | `PlayerHost`, `AllyHost`, `GuestHost`, `PlayerPortrait`, `CardInspect`, `CardHover`, `Confetti`, `FloatUpText`, `HandClearFocus`, `EndMatch`, `TableDeck` |

Prefer `WORD_GAME.Play`, `WORD_GAME.Jumble`, etc. across packages instead of deep requires.

---

## Jumble module map

### Config (`word_game/config/`)

| File | Purpose |
|------|---------|
| `round_config.lua` | 8×3 hand targets, showdown/perk/cinematic flags |
| `jumble.lua` | Letter pool (AERTNLS), deck copies, disabled 30s timer flag |
| `jumble_puzzles.lua` | Router for the 24 stage modules |
| `jumble_puzzles/*.lua` | Individual stage pattern tables such as `1_1.lua` |
| `perks.lua` | Perk pool definitions |
| `economy.lua` | Starting tokens/chips, trade pricing |

### Model (`word_game/model/`)

| File | Purpose |
|------|---------|
| `jumble/` | Puzzle spec, slot topology, validation, slots, and hand lifecycle |
| `play/` | Play-button orchestration (`play_word`, jumble bank/advance, hand clear) |
| `placement_word.lua` | `G.GAME.placement_word` / `placement_word_valid` from cards or jumble slots |
| `round.lua` | `start_hand` → `jumble.start_hand`, advance set/hand |
| `profile_stats.lua` | Profile stats, discovery tallies, career stats, input locks |
| `deck/jumble.lua` | Populate jumble deck, `deal_jumble_hand` |
| `deck/dealing.lua` | Animated `deal_into_hand` (one card at a time) |
| `perk.lua` | Offer roll, purchase, apply (partial) |
| `state.lua` | Match persistence, `alpha.tokens` |

### Cards (`word_game/model/cards/`)

| File/package | Purpose |
|------|---------|
| `definitions.lua` | Letter-card and center definitions |
| `card.lua` | Runtime letter-card domain behavior |
| `card_ability.lua` | Card ability behavior |
| `deck/` | Deck construction, population, and dealing |
| `round.lua` | Card state helpers used by the active round |

### UI (`word_game/ui/`)

| File | Purpose |
|------|---------|
| `layout/` | TABLE_BOARD geometry split: `felt.lua` (play column, felt, metrics), `vault.lua` (vault column, deck slot), `placement.lua` (portraits, banner rects, screen positions), `request.lua` (deferred layout flag for model layer) |
| `score_banner/` | Jumble score chips and “Points to get” (`fonts`, `jumble`, `draw`) |
| `timeline_timer.lua` | Fuse bar and countdown |
| `token_reward.lua` | Timer snapshot, sticker fly, spend reverse animation |
| `word_feedback.lua` | Word-play attention text on the board (loaded internally; not on facade) |
| `float_up_text.lua` | Per-card bonus popups (+2, +mult) rising from played cards |
| `hand_shuffle.lua` | Circular shuffle/play buttons flanking hand |
| `play_hold_redraw.lua` | Hold Play 5s ring, recall slots, discard hand, redeal |
| `jumble_fixed_letters.lua` | Fixed puzzle letter tile drawing and transition animation |
| `perk_stamp.lua` | Rubber-stamp perk acquisition on the vault |
| `table_deck.lua` | Draw pile + token pile rendering |
| `hand_clear_focus.lua` | Spotlight during 1-1 token award |
| `sidebar.lua` | Vault HUD (stamps, deck) |
| `widgets/` | Shared UI controls (`buttons.lua`, `sliders.lua`) and `G.UIDEF` helpers |
| `overlays/` | Options, settings, win/game-over overlays (`options.lua`, `results.lua`) |
| `stats.lua` | Profile statistics UI |
| `fx.lua` | Floating score and attention effects |
| `collection.lua` | Collection presentation |
| `menu.lua` | Main menu presentation |
| `card_ui.lua`, `card_visuals.lua` | Card presentation and visual helpers |

### Board (`word_game/board/`)

| File | Purpose |
|------|---------|
| `placement_table.lua` | Row host; wires geometry, snap, shimmer, fixed-letter draw |
| `layout.lua` | Row width/height, screen position, alignment dispatch |
| `jumble_geometry.lua` | Span/fixed screen geometry, puzzle row width, card alignment |
| `snap.lua` | Shared drag helpers and jumble slot snap |

### Integration hooks

| File | Hook |
|------|------|
| `app/loop.lua` | Engine frame + state dispatch; delegates TABLE_BOARD to `WORD_GAME.TableBoard` |
| `app/startup.lua` | Thin orchestrator; `startup/profile`, `window`, `dealing` |
| `word_game/ui/placement_controls.lua` | `play_placement_word` → `Play.play_word` (routes to jumble); loaded by `app/bootstrap.lua` |

### Score feedback roles

Three modules handle distinct score feedback layers on TABLE_BOARD:

| Module | Role |
|--------|------|
| `score_banner/` | Persistent HUD: rolling points × multiplier chips and “Points to get” target |
| `word_feedback.lua` | Ephemeral word-level attention text when a play resolves |
| `float_up_text.lua` | Short per-card bonus popups (+points, +mult) from individual cards |

---

## Package pattern

Use `snake_case` for directories and files. A package exposes one stable entry point:

```text
feature/
  init.lua
  config/
  model/
  ui/
```

When an established global callback name is used by UI definitions, keep the registration stable while moving its implementation:

```lua
local context = { module = {} }

require("feature.part_a")(context)
require("feature.part_b")(context)

return context.module
```

Application callbacks belong in `app`; gameplay actions belong in `word_game/ui` and delegate rules to `word_game/model`.

---

## Naming

- Files, directories, locals, and functions: `snake_case`.
- Classes and exported module names: `PascalCase`.
- Existing package globals: `UPPER_SNAKE_CASE` (`WORD_GAME`, `DEVTOOLS`).
- Config files contain data and simple lookups, not runtime orchestration.
- Model files describe domain behavior, not rendering.
- UI files own drawing, layout, animation, and input presentation.
- Name ambiguous concepts by domain: `letter_deck`, `deck_back`, `table_deck`, `jumble_deck` — not another unqualified `deck`.

---

## File size and cohesion

Aim for 100–250 lines per implementation file. At 300 lines, review whether the file contains multiple responsibilities. Split by behavior, not arbitrary line ranges.

Reasonable exceptions:

- generated data such as `dictionary/words_set.lua`
- localization tables
- analyzer declarations under `types/`
- cohesive inherited runtime classes where splitting would obscure inheritance
- `word_game/model/jumble/` (split across `puzzle_spec`, `validation`, `slots`, `hand`)

Large Jumbalaya-owned files should be split before inherited runtime classes.

---

## Dependency rules

`app/bootstrap.lua` is the single authoritative load order. Do not add a second bootstrap list.

Bootstrap loads the `Game` class, `G` singleton, and application shell (`app/startup.lua`, `app/save.lua`, `app/loop.lua`) before the `word_game` facade. The facade (`word_game/init.lua`) exports domain modules only.

The inheritance order is contractual:

```text
Object -> Node -> Moveable -> Sprite / UIBox / Card / CardArea
```

Additional rules:

- Do not access a load-order global from module top level unless bootstrap has already created it.
- Prefer direct `require` calls inside a package.
- Prefer the package facade (`WORD_GAME.Play`, for example) across packages.
- Keep deferred `Event` callbacks behaviorally unchanged when moving code.
- Avoid eager side effects in `init.lua`; construct runtime objects explicitly unless compatibility requires otherwise.
- Jumble snap/layout must not import UI modules; UI may import model/config.

---

## Verification

Every structural refactor should pass:

```sh
emmylua_check . --severity warn
git diff --check
love .
love tests/runner.lua
```

For package splits, compare public API names before and after. Startup success alone does not verify jumble puzzle transitions, hold-to-redraw, token fly, or perk purchase — smoke-test those manually.

Key test files for the pivot:

- `tests/unit/test_jumble_patterns.lua`
- `tests/unit/test_jumble_scoring.lua`
- `tests/unit/test_jumble_play_flow.lua`
- `tests/unit/test_timeline_timer.lua`
- `tests/unit/test_voucher_tokens.lua`

`tests/runner.lua` auto-discovers all `tests/unit/test_*.lua` files alphabetically.

---