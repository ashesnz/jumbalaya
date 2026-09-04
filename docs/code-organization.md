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
| Play button / placement | `word_game/ui/callbacks/placement.lua` (`G.FUNCS.play_placement_word`); logic in `placement_controls.lua` |
| Profile load / delete | `app/profile_callbacks.lua` |
| Settings, text input, run lifecycle | `app/callbacks/settings.lua` |
| Overlay screens (stable `G.FUNCS` names) | `word_game/ui/callbacks/overlays.lua` (installed from `app/callbacks/overlays/init.lua`) |
| Shared timed effects | `app/callbacks/effects.lua` |
| Card tooltips | `word_game/ui/card_tooltip.lua` |
| Screen wipe transitions | `app/screen_wipe.lua` (`G:queue_during_wipe`, `G:queue_wipe_transition`) |

`app/bootstrap.lua` loads callbacks in dependency order and wires `Controller._input_actions` from `app/input_actions.lua` so `app/runtime/controller.lua` does not require application code.

Obsolete collection, challenge, tutorial, promotional, social, and poker-only callbacks are removed with their active UI bindings rather than relocated into Jumbalaya packages.

### Pivot note

The **active player loop** is jumble mode (`word_game/model/jumble/` + `word_game/model/jumble_play/jumble.lua` → `play_jumble_word`). The **placement row** serves **pattern slots**, not free-form left-to-right spelling.

---

## Package entry point

`word_game/init.lua` registers the public facade as `WORD_GAME` and loads the domain packages. The facade exports only modules used across packages (`app/`, `tests/`, `devtools/`). Package-internal modules (config tables, card definitions, trade rules, etc.) are loaded via direct `require` inside `word_game/`.

| Export | Role |
|--------|------|
| `Jumble` | Puzzle state, validation, scoring, hand start |
| `Play` | Play-button orchestration: `play_jumble_word` (model evaluation), `resolve_play` / UI `play_resolution.resolve` (effects), bank/advance, hand clear, trade transition |
| `BonusStack` / `BossWordStack` | Bonus gutter state/scoring (model) and animation/draw (UI) |
| `Round` | Set/hand lifecycle, targets, perk-hand gating |
| `Deck` / `Back` | Dealing; jumble branch in `model/deck/jumble.lua` |
| `Board` | Jumble pattern row (`board/placement_table`, snap, geometry) |
| `TableBoard` | TABLE_BOARD update/draw coordinator |
| `Layout` | TABLE_BOARD geometry (`layout/felt`, `layout/vault`, `layout/placement`) |
| `ScoreBanner` | Jumble chips, multiplier, points-to-get label |
| `TimelineTimer` | 60s fuse HUD |
| `TokenReward` | 1-1 token fly animations |
| `HandShuffle` / `PlayHoldRedraw` | Shuffle + Play buttons, hold-to-redraw |
| `HandSize` | `get()` — single hand-size accessor for dealing and layout |
| `InputLock` | `is_table_busy()` — shared animation/input gate |
| `Match` | `end_run()` — centralized discard-bin surrender / game-over transition |
| `TableDiscard` | Discard bin state, eligibility, HUD sync |
| `Perks` | Perk model package (`model/perks`: registry, hand timer) |
| `TradeUI` / `PerkStamp` | Marketplace and perk stamp overlays |
| `Sidebar` | Vault HUD (stamps, deck) |
| Hosts / portraits / overlays | `PlayerHost`, `AllyHost`, `GuestHost`, `PlayerPortrait`, `CardInspect`, `CardHover`, `Confetti`, `FloatUpText`, `HandClearFocus`, `EndMatch`, `TableDeck` |

Prefer `WORD_GAME.Play`, `WORD_GAME.Jumble`, etc. across packages instead of deep requires.

---

## Jumble module map

### Config (`word_game/config/`)

| File | Purpose |
|------|---------|
| `round_config.lua` | Hand targets, `DISCARDS_PER_HAND`, `TIMELINE_SECONDS`, showdown/cinematic flags |
| `hand_size.lua` | Authoritative jumble hand size (`hand_size.get()` → `G.TABLE_HAND_SIZE` or 7) |
| `jumble.lua` | Letter pool (AERTNLS), deck copies, disabled 30s timer flag |
| `jumble_puzzles.lua` | Router for the 24 stage modules |
| `jumble_puzzles/*.lua` | Individual stage pattern tables such as `1_1.lua` |
| `perks.lua` | Perk pool definitions (cosmetic until effects wire) |
| `economy.lua` | Starting tokens/chips, trade pricing |

### Model (`word_game/model/`)

| File | Purpose |
|------|---------|
| `jumble/` | Puzzle spec, slot topology, validation, slots, and hand lifecycle |
| `jumble_play/` | Jumble play evaluation (`play_jumble_word` returns result; no UI imports) |
| `bonus_stack.lua` | Bonus gutter card stack state, scoring, hand-start staging |
| `board/bonus_gutter.lua` | Bonus stack layout geometry and drag/snap helpers (no UI imports from model) |
| `placement_word.lua` | `G.GAME.placement_word` / `placement_word_valid` from jumble slots |
| `round.lua` | `start_hand` → `jumble.start_hand`, advance set/hand, `reset_timeline()` |
| `input_lock.lua` | Animation-busy gate for play/discard/drag |
| `match.lua` | Match-end / game-over transition from discard bin |
| `feedback.lua` | Model-layer attention text queue (drained by `word_feedback`) |
| `profile_stats.lua` | Minimal card discovery persistence |
| `deck/jumble.lua` | Populate jumble deck, `deal_jumble_hand` |
| `deck/dealing.lua` | Animated `deal_into_hand` (one card at a time) |
| `perks/` | Perk registry (`registry.lua`), per-hand timer stub (`timer.lua`; `ENABLED = false`) |
| `perk.lua` | Shim → `model/perks/registry` |
| `state.lua` | Match persistence, `run_state.tokens` / `run_state.perks` |

### Cards (`word_game/model/cards/`)

| File/package | Purpose |
|------|---------|
| `definitions.lua` | Letter-card and center definitions |
| `card.lua` | Runtime letter-card domain behavior |
| `card_ability.lua` | Card ability behavior |
| `deck/` | Deck construction, population, and dealing |

### UI (`word_game/ui/`)

| File | Purpose |
|------|---------|
| `layout/` | TABLE_BOARD geometry split: `felt.lua` (play column, felt, metrics), `vault.lua` (vault column, deck slot), `placement.lua` (portraits, banner rects, screen positions), `request.lua` (deferred layout flag for model layer) |
| `score_banner/` | Jumble score chips and “Points to get” (`fonts`, `jumble`, `draw`) |
| `perks/` | Perk-adjacent UI: `discard_bin/` (`bin_enabled()` gate), `timeline_timer/` (fuse/slider), `stamp_grid.lua`, `voucher.lua`; shims at `table_discard.lua`, `timeline_timer/`, `stamp_grid.lua`, `perk_voucher.lua` |
| `trade/` | Marketplace overlay (`definition`, `draw`, `animate`, `fly`, `layout`; session/input in `init`) |
| `perks/stamp/` | Rubber-stamp perk acquisition (`definition`, `draw`, `animate`, `layout`; facade in `init`; shim at `perk_stamp/`) |
| `play_effects/` | Play resolution cinematics (`definition` feedback/banners, `animate` sequences; facade in `init`) |
| `play_resolution.lua` | Drains model play result into `play_effects` (keeps `jumble_play` headless-testable) |
| `boss_word_stack/` | Bonus gutter presentation (`layout`, `animate`, `draw`; facade in `init`; model in `bonus_stack`) |
| `token_reward.lua` | Timer snapshot, sticker fly, spend reverse animation |
| `word_feedback.lua` | Ephemeral word-level attention text when a play resolves (single API; drains `model/feedback`) |
| `float_up_text.lua` | Per-card bonus popups (+2, +mult) rising from played cards |
| `hand_shuffle/` | Circular shuffle/play buttons (`definition`, `layout`, `animate`, `shuffle_anim`, `placement_recall_anim`; facade in `init`) |
| `play_hold_redraw.lua` | Hold Play 5s ring, recall slots, discard hand, redeal |
| `jumble_fixed_letters.lua` | Fixed puzzle letter tile drawing and transition animation |
| `table_deck.lua` | Draw pile + token pile rendering |
| `hand_clear_focus.lua` | Spotlight during 1-1 token award |
| `sidebar.lua` | Vault HUD (stamps, deck) |
| `widgets/` | Shared UI controls (`buttons.lua`, `sliders.lua`) and `G.DEFINITIONS` helpers |
| `overlays/` | Options, settings, win/game-over overlays (`options.lua`, `results.lua`) |
| `word_feedback.lua` | Gameplay attention text; owns `spawn_attention` primitive |
| `fx.lua` | Boot shim that loads `word_feedback` (installs global `spawn_attention`) |
| `menu/` | Main menu (`definition`, `layout`, `animate`; facade in `init`) |
| `card_ui.lua`, `card_visuals.lua` | Card presentation and visual helpers |
| `cardarea/` | `CardArea` class (`hand`, `deck`, `discard`, `placement` type handlers; `selection`, `relayout`, `chrome`; facade in `init`) |

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
| `word_game/ui/callbacks/placement.lua` | `play_placement_word` → `placement_controls.try_play` |

### Play resolution split

Model evaluation and UI presentation are separated for headless tests:

| Layer | Module | Role |
|-------|--------|------|
| Model | `jumble_play/jumble.lua` | `play_jumble_word()` → evaluation result only |
| UI | `play_resolution.lua` | `resolve(Play)` → `play_effects` banners, fly, hand clear |
| UI | `placement_controls.lua` | Play button calls `play_resolution.resolve` |

Tests that need full play behavior call `play_resolution.resolve(flow)`; tests that only need rules call `play_jumble_word` or `rules.evaluate_play` directly.

### Score feedback roles

Three modules handle distinct score feedback layers on TABLE_BOARD. Use this routing:

| Layer | Module | When to use |
|-------|--------|-------------|
| Persistent HUD | `score_banner/` | Rolling points × multiplier chips and “Points to get” |
| Ephemeral sentences | `word_feedback.lua` | Immediate board messages during play (invalid word, hand cleared, boss countdown) |
| Model queue | `model/feedback.lua` | Rules/model code that must not import UI; drained by `word_feedback.flush_pending()` |
| Low-level primitive | `word_feedback.spawn_attention` | Anchor-specific or engine-level text; avoid from model |
| Play cinematics | `play_effects/` | Full play resolution FX; delegates copy to `word_feedback` |
| Per-card popups | `float_up_text.lua` | Short +2 / +mult rises from individual cards |

`spawn_attention` is installed as a global by `word_feedback.lua` (via `fx.lua` at boot). New gameplay copy should go through `word_feedback` helpers or `model/feedback`.

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
- Two schedulers exist by design: `app/core/util/scheduler.lua` (tween lane manager) and `app/effects/timeline_scheduler.lua` (G.TIMELINE wrapper).

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