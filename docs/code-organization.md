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
app/core/                Rendering, input, scene graph, UI classes, and shared engine helpers
word_game/
  board/                 jumble pattern row — placement/, jumble/, bonus/
  config/                static tuning: round targets, puzzles, perks, and runtime options
  model/                 gameplay state, card domain, deck, flow, and round rules
    game/                Game class: init, prep_stage, start_run, loop hooks
  ui/                    gameplay presentation, layouts, controls, and UI definitions
    table/               TABLE_BOARD coordinator, deck, input, controls
      board.lua          update/draw coordinator (used from app/core/session/loop.lua)
devtools/                development-only tools (stage jump, word hints)
dictionary/              offline word list and playability checks
types/                   analyzer-only EmmyLua declarations
docs/                    player and design documentation (this folder)
```

### UI foundation versus word-game UI

These two UI locations serve different layers and should not be merged:

- `app/core/ui/` defines the reusable panel/node scene graph (`panel.lua`, `node.lua`, …). It owns layout measurement, alignment, hit testing, focus, animation hooks, and drawing; it must remain independent of Jumbalaya screens and gameplay.
- `word_game/ui/` defines Jumbalaya presentation such as the HUD, cards, menus, overlays, controls, and board layouts. These modules build UI definitions and connect them to word-game state.

The dependency direction is `word_game/ui/` → `app/core/`. Moving the engine classes into `word_game/ui/` would couple the reusable engine layer to the game and would not remove duplicated functionality. New generic UI primitives belong in `app/core/`; game-specific UI belongs in `word_game/ui/`.

`app/core/graphics/flow_text.lua` follows the same boundary. `DynaText` owns measurement, animated letter rendering, scaling, and alignment. Its reads from `G.LANG`, `G.C`, `G.TIMERS`, and `G.I.MOVEABLE` are engine runtime contracts supplied during bootstrap; localization choices, number formatting, and presentation copy remain in `word_game/ui/`.

### Callback ownership

Callbacks are grouped by responsibility under `app/callbacks/` and `word_game/ui/`:

| Area | Module |
|------|--------|
| HUD refresh / rebuild | `word_game/ui/sidebar/` via `WORD_GAME_UI.Sidebar`; G.FUNCS in `sidebar/funcs.lua` |
| Screen / placement layout | `word_game/ui/layout/` via `WORD_GAME_UI.Layout` or `require "word_game.ui.layout"`; model code requests deferred layout via `word_game.model.layout.request` |
| Play button / placement | `word_game/ui/callbacks/placement.lua` (`G.FUNCS.play_placement_word`); logic in `table/controls/placement.lua` |
| Profile load / delete | `app/profile_callbacks.lua` |
| Settings, text input, run lifecycle | `app/callbacks/settings.lua` |
| Overlay screens (stable `G.FUNCS` names) | `word_game/ui/callbacks/overlays.lua` (installed from `app/callbacks/overlays/init.lua`) |
| Shared timed effects | `app/callbacks/effects.lua` |
| Card tooltips | `word_game/ui/cards/tooltip.lua` |
| Screen wipe transitions | `app/screen_wipe.lua` (`G:queue_during_wipe`, `G:queue_wipe_transition`) |

`app/bootstrap.lua` loads callbacks in dependency order and wires input actions from `app/input_actions.lua` so `app/core/input/router.lua` does not require application code.

Obsolete collection, challenge, tutorial, promotional, social, and poker-only callbacks are removed with their active UI bindings rather than relocated into Jumbalaya packages.

### Pivot note

The **active player loop** is jumble mode (`word_game/model/jumble/` + `word_game/model/jumble_play/jumble.lua` → `play_jumble_word`). The **placement row** serves **pattern slots**, not free-form left-to-right spelling.

---

## Package entry point

`word_game/init.lua` registers the domain facade as `WORD_GAME`. Presentation is `WORD_GAME_UI` from `word_game/ui/facade/exports.lua`. `app/`, `tests/`, and `devtools/` should use those tables instead of deep requires. Model/board code emits `word_game.model.presentation` events; it must not call `WORD_GAME_UI` or `G.FUNCS`. Named `G.FUNCS` strings are catalogued in `types/g_funcs.lua`.

### Domain (`WORD_GAME`)

| Export | Role |
|--------|------|
| `Jumble` | Puzzle state, validation, scoring, hand start; also `Jumble.BonusStack`, `Jumble.PlacementWord`, `Jumble.return_bonus_card` |
| `PlacementWord` | Placement-row word preview on `G.GAME` (`clear`, `refresh_from_jumble_slots`) |
| `JumbleRules` | Pure scoring/play rules (`compute_word_score`, `score_breakdown`, `evaluate_play`, …) |
| `Play` | Play-button orchestration (`play_jumble_word`); sub-exports `Play.Rules`, `Play.ModifierEffects` |
| `BonusStack` | Bonus gutter state/scoring |
| `Round` | Set/hand lifecycle, targets, perk-hand gating |
| `Deck` / `Back` | Dealing; jumble branch in `model/cards/deck/jumble.lua` |
| `Board` | Jumble pattern row (`placement/table`, `placement/snap`, `jumble/geometry`, `bonus/gutter`) |
| `HandSize` | `get()` — single hand-size accessor for dealing and layout |
| `Busy` / `InputLock` | Table-busy flags on `G.GAME` and `is_table_busy()` |
| `Timeline` | Domain reads of fuse seconds / classic goal (`G.GAME` mirror from `TimelineTimer`) |
| `Match` | `end_run()` — centralized discard-bin surrender / game-over transition |
| `VoucherDiscard` | Discard-bin allowance rules (`model/perks/voucher_discard`) |
| `Perks` | Perk model package (`model/perks`: registry, effects, hand timer) |

### Presentation (`WORD_GAME_UI`)

| Export | Role |
|--------|------|
| `TableBoard` | TABLE_BOARD update/draw coordinator |
| `Layout` | TABLE_BOARD geometry (`layout/felt`, `sidebar/layout`, `layout/placement`) |
| `ScoreBanner` | Jumble chips, multiplier, points-to-get label |
| `TimelineTimer` | 60s fuse HUD |
| `TokenReward` | 1-1 token fly animations |
| `HandShuffleAnim` / `PlayHoldRedraw` | Shuffle animation + hold-to-redraw (under `table/controls/`) |
| `TableControls` | Play + shuffle/remove buttons beside the dealt hand |
| `TradeUI` / `PerkStamp` | Marketplace and perk stamp overlays |
| `Sidebar` | Right-hand HUD (stamps, deck, End Run) |
| `SidebarStageButton` | Classic End Run / Next button in the sidebar |
| `BonusStackUI` | Bonus gutter animation/draw |
| Table input / overlays | `TableInput`, `CardInspect`, `Confetti`, `FloatUpText`, `HandClearFocus`, `EndMatch`, `TableDeck` |

### Require conventions

| Caller | Rule |
|--------|------|
| `app/`, `tests/`, `devtools/` | Use `WORD_GAME` / `WORD_GAME_UI` — no deep `word_game.model.*` requires unless testing internals |
| `word_game/ui/` | `word_game.ui.facade` for cross-package imports (model/board/app); top-of-file `require` for sibling UI modules only |
| `word_game/board/` | Top-of-file `require` for model modules; no UI imports at load time |
| `word_game/model/` | Top-of-file `require` for siblings (`model/jumble/*`, `model/run/*`, …); use `jumble/bonus_return` when model must return bonus cards to the gutter |
| Inline `require(...)` inside functions | Avoid — hoist to module scope unless breaking a documented circular dependency |
| `Card` presentation | Model class in `model/cards/card.lua`; draw/tooltip mixins install from `ui/cards/bind.lua` at boot (not from model) |
| Layout refresh | `word_game/model/layout/request.lua` sets `G.ARGS.pending_layout`; model code must not `require` `word_game.ui.layout` |
| Timeline reads | `word_game/model/run/timeline.lua` reads `G.GAME.timeline_*` mirrored by `TimelineTimer`; model emits `timeline_apply_seconds` (never queries UI via `Presentation.emit`) |
| UI reactions | `word_game/model/presentation.lua` emits events; `word_game/ui/presentation/install.lua` registers handlers at boot |

Prefer `WORD_GAME.Play`, `WORD_GAME.Jumble`, `WORD_GAME_UI.BonusStackUI`, etc. across package boundaries instead of deep requires.

---

## Perks

Perk-adjacent code is grouped under `word_game/model/perks/` and `word_game/ui/perks/`. Gameplay hooks live in `model/perks/effects.lua` (`WORD_GAME.Perks.Effects`); config pool in `config/perks.lua`.

| Piece | Location | Notes |
|-------|----------|-------|
| Effect hooks | `model/perks/effects.lua` | Scoring, combo, hand size, timeline, redraw |
| Registry / rolls | `model/perks/registry.lua` | Stamp reward selection |
| Hand timer | `model/perks/timer.lua` | Per-puzzle deadline stub (`ENABLED = false`); distinct from fuse HUD |
| Discard voucher | `ui/perks/discard_bin/` | Unlocks with first perk; drag hand cards onto imprint |
| Timeline fuse | `ui/perks/timeline_timer/` | Self-registers updater |
| Stamp animation | `ui/perks/stamp/` | Rubber-stamp acquisition UI |
| Stamp grid / voucher | `ui/perks/stamp/grid.lua`, `ui/perks/shared/voucher.lua` | Sidebar stamp layout and marketplace sprites |

Future wiring targets: flip `timer.lua` `ENABLED` when hand deadlines ship.

---

## Jumble module map

### Config (`word_game/config/`)

`word_game/config/` has **no root-level modules** — use subpackage paths or `require("word_game.config")`.

| Package | Purpose |
|---------|---------|
| `boot/` | `runtime` (LÖVE `love.conf`), `runtime_options` (feature flags), `env` (`.env` overrides) |
| `layout/` | `dimensions` — tile scale, card size, TABLE_BOARD layout constants |
| `visuals/` | `palette`, `letter_card_palette`, `deck_face_colors` (generated) |
| `gameplay/` | `round` (hand targets, timeline), `economy` (tokens/trade), `run_params` |
| `perks/` | Perk pool definitions (effects in `model/perks/effects.lua`) |
| `jumble/` | Puzzle router (`init.lua`) + `puzzles/{set}_{hand}.lua` stage tables |

Runtime hand size (`WORD_GAME.HandSize.get()`) lives in `word_game/model/hand_size.lua` (base from `layout.dimensions` + perk bonus).

### Model (`word_game/model/`)

`word_game/model/` has **no root-level modules** — use subpackage paths only.

| Package | Purpose |
|---------|---------|
| `game/` | `Game` class (`init.lua`, `run.lua`, `loop.lua`), `globals.lua` (`G = Game()`) |
| `run/` | Run lifecycle facade (`init.lua` → `.State`, `.Scope`, `.Mode`, `.Match`, `.InputLock`, `.Register`) |
| `round/` | Set/hand controller: `start_hand`, advance, timeline reset |
| `trade/` | The Trade marketplace offers and actions |
| `jumble/` | Puzzle spec, slots, validation, hand lifecycle, `bonus_stack`, `placement_word` |
| `jumble_play/` | Play evaluation (`play_jumble_word`); hand-clear orchestration |
| `cards/` | Letter-card definitions, `Card` class, `deck/` dealing |
| `perks/` | Registry, effect hooks, per-hand timer stub |
| `feedback/` | Model-layer attention text queue (drained by `word_feedback`) |
| `meta/` | `profile_stats` — card discovery persistence |

### Cards (`word_game/model/cards/`)

| File/package | Purpose |
|------|---------|
| `definitions.lua` | Letter-card and center definitions |
| `card.lua` | Runtime letter-card domain behavior |
| `card_ability.lua` | Card ability behavior |
| `deck/` | Deck construction, population, and dealing |

### UI (`word_game/ui/`)

`word_game/ui/` has **no root-level modules** — everything lives in subpackages below. Always require the package path (e.g. `word_game.ui.table.board`, not `word_game.ui.table_board`).

| Package | Purpose |
|---------|---------|
| `util/` | Stateless helpers: `colour`, `localize`, `number_format`, `roll` |
| `facade/` | Cross-package resolver — UI modules import model/board via `require("word_game.ui.facade")` |
| `cards/` | Letter card presentation: `tooltip`, `popups`, `visuals`, `ui`, `letter_faces`, `inspect` |
| `table/` | TABLE_BOARD coordinator and table chrome: `board`, `deck`, `input`, `dealt_hand`, `jumble_fixed_letters`, `token_reward` |
| `table/controls/` | Play/shuffle buttons (`init`, `placement`, `play_hold_redraw`, `shuffle_anim`, …) |
| `feedback/` | Ephemeral copy and FX: `word_feedback`, `float_up_text`, `modifier_feedback`, `comic_burst`, `confetti` |
| `tutorial/` | First-play onboarding: `first_play`, `character_speech`, `hand_clear_focus` |
| `layout/` | TABLE_BOARD geometry: `felt`, `placement`, `request` |
| `sidebar/` | Right-hand HUD: `init`, `hud_definition`, `layout`, `stage_button`, `funcs` |
| `score_banner/` | Jumble score chips, “Points to get”, `stage_label`, `boss_announce` |
| `play_effects/` | Play cinematics + `resolution` (model result → FX) and `card_fly_off` |
| `perks/` | `bonus_stack/` (boss-word gutter), `discard_bin/`, `timeline_timer/`, `stamp/` (grid + animation), `shared/` (voucher atlas + sprite) |
| `trade/` | Marketplace overlay |
| `menu/` | Main menu + `title_logo` |
| `overlays/` | Options, settings, results, `end_match` |
| `widgets/` | Shared controls + `odometer` |
| `callbacks/` | `G.FUNCS` bindings (`table_controls`, `trade`, `placement`, `overlays`) |
| `cardarea/` | `CardArea` class — boot via `require "word_game.ui.cardarea.init"` |
| `sidebar/` | Right-hand HUD — boot via `require "word_game.ui.sidebar.init"` |

### Board (`word_game/board/`)

Only `init.lua` at package root — subpackages:

| Path | Purpose |
|------|---------|
| `placement/table.lua` | Row host (`PlacementTable`); wires geometry, snap, shimmer |
| `placement/layout.lua` | Row width/height, screen position, alignment dispatch |
| `placement/snap.lua` | Shared drag helpers and jumble slot snap |
| `placement/shimmer.lua` | Lock-in outline FX around placed cards |
| `placement/config.lua` | Row tunables (spacing, boss gap, shimmer duration) |
| `jumble/geometry.lua` | Span/fixed screen geometry, puzzle row width, card alignment |
| `bonus/gutter.lua` | Bonus stack layout and drag/snap hit tests |

Fixed-letter tile draw is installed from `ui/table/board.lua` via `placement_table.draw_pattern_overlay`.

### Integration hooks

| File | Hook |
|------|------|
| `app/core/session/loop.lua` | Engine frame + state dispatch; delegates TABLE_BOARD to `WORD_GAME_UI.TableBoard` |
| `app/startup.lua` | Thin orchestrator; `startup/profile`, `window`, `dealing` |
| `word_game/ui/callbacks/placement.lua` | `play_placement_word` → `controls/placement.try_play` |

### Play resolution split

Model evaluation and UI presentation are separated for headless tests:

| Layer | Module | Role |
|-------|--------|------|
| Model | `jumble_play/jumble.lua` | `play_jumble_word()` → evaluation result only |
| UI | `play_effects/resolution.lua` | `resolve(Play)` → `play_effects` banners, fly, hand clear |
| UI | `table/controls/placement.lua` | Play button calls `play_effects/resolution.resolve` |

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

Bootstrap is split into `app/bootstrap/engine_boot.lua` (engine classes, `G`, schedulers) and `app/bootstrap/game_boot.lua` (word-game facade, presentation wiring, `G.FUNCS`). Any new package in the layout or presentation chain must be checked for circular `require` with model code — model must not import `word_game/ui/` at module top level.

Bootstrap loads the `Game` class, `G` singleton, and application shell (`app/startup.lua`, `app/core/persistence/save.lua`, `app/core/session/loop.lua`) before the `word_game` facade. The facade (`word_game/init.lua`) exports domain modules only. Presentation callbacks (`hand_clear.install`, `ui/cards/bind`, `ui/presentation/install`) are wired in `game_boot.lua`, not in model modules.

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