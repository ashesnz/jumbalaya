# Code organization

Jumbalaya is organized in **four cooperating layers**. They are not duplicates — each has a distinct job:

| Layer | Path | Role |
|-------|------|------|
| **Application** | `games/jumbalaya/app/` | Love2D entry, bootstrap, lifecycle, input callbacks, persistence shell |
| **Portable core** | `packages/jumbalaya_core/` | Engine-agnostic rules, store, reducers — **no Love2D, no globals** |
| **Portable engine** | `packages/jumbalaya-engine/` | Service interfaces (clock, input map, event bus, retained UI, views) |
| **This game** | `games/jumbalaya/word_game/` | Jumbalaya runtime glue, presentation, board geometry, game-specific config |

Shell wiring (`app/runtime.lua`, `app/callbacks/funcs.lua`, `app/bootstrap/store_sync.lua`, `jumbalaya-engine.shell`) is injected at boot via `app/bootstrap/shell_bind.lua`. The old `bridge/` folder is dissolved.

**Do not delete `app/` or `packages/`** — see [app vs packages](#app-vs-packages) below. The long-term plan is to *shrink* `app/core/` into `jumbalaya-engine`, not merge everything back into one tree.

### Engine migration

Phases 0–13 are **complete** (store, engine package, retained UI, `Funcs` registry, no global `G`, `games/jumbalaya/` layout). **Phase 10a** (glue hygiene) continues incrementally.

**Freeze policy (ongoing):**

- No new run-state keys without a declared owner in `types/store.lua` **and** a reducer/default in `jumbalaya_core` — enforced by `tests/unit/test_store_state_catalog.lua`.
- No new UIBox callback names without an entry in `types/funcs.lua` — enforced by `tests/unit/test_g_funcs_registry.lua`.
- No new deep `word_game.model.*` / `word_game.ui.*` requires across `app/` (bootstrap wiring exempt), `devtools/`, or `word_game/ui/` (grandfathered allowlist) — enforced by `tests/unit/test_facade_boundaries.lua`.
- New features ship via `WORD_GAME` / `WORD_GAME_UI` facade methods; model code uses `Presentation.emit`, not `Funcs.dispatch`.
- Store authority lives on `WORD_GAME.store()` / `game_access`; `app/bootstrap/store_sync.lua` creates the store and binds runs at boot.

---

## Directory responsibilities

```text
packages/
  jumbalaya_core/               Portable domain: store, rules, jumble, cards, config (headless-testable)
  jumbalaya-engine/             Portable engine: retained_ui, clock, input, event_bus, views
games/jumbalaya/
  app/                          Love2D shell: bootstrap, callbacks, startup, session/persistence
  word_game/                    Runtime glue, presentation, board geometry, config
  devtools/                     Dev-only panel (snake_case Lua modules under devtools/sections/)
  dictionary/                   Offline word validation
  localization/                 Locale tables (e.g. en-us.lua — BCP47 tag, not snake_case)
  tests/                        Headless suite — love games/jumbalaya tests
docs/                           Design and engineering documentation (this folder)
_tools/                         Python asset/dev pipelines (not runtime)
```

### app vs packages

| Question | Answer |
|----------|--------|
| Why both `app/` and `packages/`? | `app/` **runs** this Love2D game. `packages/` holds **libraries** extracted so rules and engine services can be tested and reused without the full boot chain. |
| Can we remove `packages/`? | **No** — store, reducers, core rules, retained UI, and `test_core_*` depend on it. |
| Can we remove `app/`? | **No** — bootstrap, Love2D callbacks, and most of the scene graph still live here. |
| What is duplicated? | `app/core/` and `packages/jumbalaya-engine/` overlap **during migration** (`retained_ui` already moved; Card/Sprite/input still in `app/core/`). That overlap shrinks over time; do not collapse the trees prematurely. |
| Dependency direction | `jumbalaya_core` imports nothing from `app/` or `word_game/`. `jumbalaya-engine` may import `app/core/scene/` (e.g. `AnimNode`). `word_game/` imports both. `app/` imports `word_game/` at boot only. |

### word_game vs jumbalaya_core

`word_game/model/` and `packages/jumbalaya_core/` look similar because most **rules already moved to core**; `word_game` modules are now **runtime glue**, not a second copy of the logic.

```text
packages/jumbalaya_core/     Pure functions on plain tables (headless CI)
        ↓ require
word_game/model/             Glue: live_game(), store dispatch, Card/CardArea, save format
        ↓ facade
word_game/ui/                Presentation only
```

| Module kind | Put it in | Examples |
|-------------|-----------|----------|
| Pure rule (no Love2D, no globals) | `jumbalaya_core/` | `rules/jumble.lua`, `jumble/validation.lua`, `store/reducers/` |
| Static tuning (engine-agnostic) | `jumbalaya_core/config/` | `gameplay/round.lua`, `gameplay/economy.lua` — re-exported from `word_game/config/` where the facade expects it |
| Game-specific puzzle data | `word_game/config/jumble/puzzles/` | Per-stage pattern tables — not portable |
| Runtime wiring (Card, deck, save) | `word_game/model/` | `cards/deck/`, `persistence/`, `game/run.lua` |
| Screen layout / FX | `word_game/ui/` | HUD, banners, play effects |

Glue modules are often labeled *"glue over jumbalaya_core"* in their file headers. A typical glue file:

1. `require("jumbalaya_core.rules.*")` for the pure rule
2. Read/write state via `live_game()` / `game_access.get()` / `WORD_GAME.store()`
3. Emit UI events via `Presentation.emit` — never import `word_game/ui/`

**When adding gameplay logic:** implement the rule in `jumbalaya_core` first (with a `test_core_*` test), then add the thinnest possible glue in `word_game/model/`. Do not duplicate rule logic in `word_game/` — extend core and call it.

**Config re-exports:** `word_game/config/gameplay/round.lua` and `economy.lua` are one-line re-exports of `jumbalaya_core` so existing `require("word_game.config.gameplay.*")` paths stay stable. New engine-agnostic tuning goes in `jumbalaya_core/config/`; game-only data (jumble puzzles, visuals, boot flags) stays in `word_game/config/`.

### UI foundation versus word-game UI

These layers serve different purposes and should not be merged:

- `packages/jumbalaya-engine/retained_ui/` — reusable panel/node scene graph (`RetainedPanel`, layout, hit testing, focus). Moved from `app/core/ui/` in Phase 8 PR-8.
- `app/core/scene/` + `app/core/graphics/` — lower-level scene nodes (`AnimNode`, `Sprite`, particles, `DynaText`).
- `word_game/ui/` — Jumbalaya screens: HUD, cards, menus, overlays, TABLE_BOARD layout.

Dependency direction: `word_game/ui/` → `jumbalaya-engine` + `app/core/` → never reverse into gameplay rules.

`jumbalaya-engine/graphics/flow_text.lua` (`DynaText`) reads colours and timers from the bound **Game shell** (`jumbalaya-engine.shell`); localization copy lives in `games/jumbalaya/localization/`.

### Callback ownership

UIBox buttons still bind **string names** (`func = 'shuffle_hand'`). Runtime dispatch goes through `app/callbacks/funcs.lua` (`Funcs.register`, `Funcs.dispatch`). Implementations live in `app/callbacks/` and `word_game/ui/callbacks/`.

| Area | Module |
|------|--------|
| HUD refresh / rebuild | `word_game/ui/sidebar/` via `WORD_GAME_UI.Sidebar`; handlers in `sidebar/funcs.lua` |
| Screen / placement layout | `word_game/ui/layout/` via `WORD_GAME_UI.Layout`; model requests layout via `word_game.model.layout.request` |
| Play button / placement | `word_game/ui/callbacks/placement.lua` (`play_placement_word`); logic in `table/controls/placement.lua` |
| Profile load / delete | `app/profile_callbacks.lua` |
| Settings, text input, run lifecycle | `app/callbacks/settings.lua` |
| Overlay screens (stable string names) | `word_game/ui/callbacks/overlays.lua` (installed from `app/callbacks/overlays/init.lua`) |
| Shared timed effects | `app/callbacks/effects.lua` |
| Card tooltips | `word_game/ui/cards/tooltip.lua` |
| Screen wipe transitions | `app/screen_wipe.lua` |

`app/bootstrap.lua` loads callbacks in dependency order and wires input actions from `app/input_actions.lua` so `app/core/input/router.lua` does not require application code.

### Pivot note

The **active player loop** is jumble mode (`word_game/model/jumble/` + `word_game/model/jumble_play/jumble.lua` → `play_jumble_word`). The **placement row** serves **pattern slots**, not free-form left-to-right spelling.

---

## Package entry point

`word_game/init.lua` registers the domain facade as `WORD_GAME`. Presentation is `WORD_GAME_UI` from `word_game/ui/facade/exports.lua`. `app/`, `tests/`, and `devtools/` should use those tables instead of deep requires.

**Runtime bus:**

| Concern | Access |
|---------|--------|
| Game shell (settings, scene nodes, timers) | `app/runtime.lua` → `jumbalaya-engine.shell` |
| Run snapshot | `WORD_GAME.store()` / `game_access.get()` on `Game.GAME` |
| UIBox string callbacks | `app/callbacks/funcs.lua` → `Funcs.dispatch("name", …)` |
| Model → UI notify | `Presentation.emit` (contract: `types/presentation.lua`) |

**Stop growing ad hoc state:** every new feature ships with a **facade method + owned run-state field** (declared in `types/game.lua`) or it does not land. Callback string names are registration only; logic lives on `WORD_GAME_UI` / app modules.

**Engine vs game:** `app/core/` is the Love scene graph (Card, CardArea, input, loop). It must not reference jumble, letter faces, or card rules. Letter identity lives in `word_game/model/cards/`. Run save/restore lives in `word_game/model/persistence/` (`WORD_GAME.Persistence`); `app/core/persistence/save.lua` snapshots CardAreas and delegates.

### Domain (`WORD_GAME`)

| Export | Role |
|--------|------|
| `Jumble` | Puzzle state, validation, scoring, hand start; also `Jumble.BonusStack`, `Jumble.PlacementWord`, `Jumble.return_bonus_card` |
| `PlacementWord` | Placement-row word preview on run state (`clear`, `refresh_from_jumble_slots`) |
| `JumbleRules` | Pure scoring/play rules (`compute_word_score`, `score_breakdown`, `evaluate_play`, …) |
| `Play` | Play-button orchestration (`play_jumble_word`); sub-exports `Play.Rules`, `Play.ModifierEffects` |
| `BonusStack` | Bonus gutter state/scoring |
| `Round` | Set/hand lifecycle, targets, perk-hand gating |
| `Deck` / `Back` | Dealing; jumble branch in `model/cards/deck/jumble.lua` |
| `Board` | Jumble pattern row (`placement/table`, `placement/snap`, `jumble/geometry`, `bonus/gutter`) |
| `HandSize` | `get()` — single hand-size accessor for dealing and layout |
| `Busy` / `InputLock` | Table-busy flags on run state (FX modules push); `is_table_busy()` |
| `Timeline` | Authoritative fuse seconds on run state; classic goal/target reads |
| `Match` | `end_run()` — centralized discard-bin surrender / game-over transition |
| `VoucherDiscard` | Discard-bin allowance rules (`model/perks/voucher_discard`) |
| `Perks` | Perk model package (`model/perks`: registry, effects) |
| `store()` / `engine()` | Bound `jumbalaya_core` store and `jumbalaya-engine` services |

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
| `word_game/ui/` | `word_game.ui.facade` for cross-package imports; `word_game.ui.util.game_runtime` for the Game shell |
| `word_game/board/` | Top-of-file `require` for model modules; no UI imports at load time |
| `word_game/model/` | Prefer `jumbalaya_core` for pure rules; glue reads `live_game()` / `game_access.get()` |
| `jumbalaya_core/` | **Never** import `app/`, `word_game/`, or Love2D |
| Inline `require(...)` inside functions | Avoid — hoist to module scope unless breaking a documented circular dependency |
| `Card` presentation | Model class in `model/cards/card.lua`; draw/tooltip mixins install from `ui/cards/bind.lua` at boot |
| Layout refresh | `word_game/model/layout/request.lua` sets pending layout on the Game shell; model must not `require` `word_game.ui.layout` |
| Run-state field owners | `types/game.lua` | Declared keys + owning module; no ad-hoc fields |
| Callback string names | `types/funcs.lua` | Catalog for UIBox/button handlers |
| UI reactions | `Presentation` + `ui/presentation/install.lua` | Contract in `types/presentation.lua` |
| Headless rule tests | `tests/unit/test_core_*.lua` | Call `jumbalaya_core` directly — no `mock_env` needed |

Prefer `WORD_GAME.Play`, `WORD_GAME.Jumble`, `WORD_GAME_UI.BonusStackUI`, etc. across package boundaries instead of deep requires.

---

## Perks

Perk-adjacent code is grouped under `word_game/model/perks/` and `word_game/ui/perks/`. Pure perk math lives in `jumbalaya_core/rules/`; glue in `model/perks/effects.lua` (`WORD_GAME.Perks.Effects`).

| Piece | Location | Notes |
|-------|----------|-------|
| Effect hooks | `model/perks/effects.lua` | Glue over `jumbalaya_core.rules.perk_effects` |
| Registry / rolls | `model/perks/registry.lua` | Glue over `jumbalaya_core.perks.registry` |
| Discard voucher | `ui/perks/discard_bin/` | Unlocks with first perk; drag hand cards onto imprint |
| Timeline fuse | `model/run/timeline.lua` + `ui/perks/timeline_timer/` | Authoritative fuse on run state; HUD draw/sync only |
| Stamp animation | `ui/perks/stamp/` | Rubber-stamp acquisition UI |
| Stamp grid / voucher | `ui/perks/stamp/grid.lua`, `ui/perks/shared/voucher.lua` | Sidebar stamp layout and marketplace sprites |

---

## Jumble module map

### Config (`word_game/config/`)

`word_game/config/` has **no root-level modules** — use subpackage paths or `require("word_game.config")`.

| Package | Purpose |
|---------|---------|
| `boot/` | `runtime` (LÖVE `love.conf`), `runtime_options` (feature flags), `env` (`.env` overrides) |
| `layout/` | `dimensions` — tile scale, card size, TABLE_BOARD layout constants |
| `visuals/` | `palette`, `letter_card_palette`, `deck_face_colors` (generated) |
| `gameplay/` | `round`, `economy` re-export `jumbalaya_core`; `run_params` is game-specific |
| `perks/` | Perk pool definitions (effects glue in `model/perks/effects.lua`) |
| `jumble/` | Puzzle router (`init.lua`) + `puzzles/{set}_{hand}.lua` stage tables |

Runtime hand size (`WORD_GAME.HandSize.get()`) glue lives in `word_game/model/hand_size.lua` (core rule in `jumbalaya_core.rules.hand_size`).

### Model (`word_game/model/`)

`word_game/model/` has **no root-level modules** — use subpackage paths only. Most rule modules are thin glue over `jumbalaya_core`.

| Package | Purpose |
|---------|---------|
| `game/` | `Game` class (`init.lua`, `run.lua`, `loop.lua`), `globals.lua` (`define_constants`) |
| `live_game.lua` | `live_game()` → `BridgeRuntime.game()` for model-layer shell access |
| `game_access.lua` | Run snapshot reads via store |
| `run/` | Run lifecycle facade (`init.lua` → `.State`, `.Scope`, `.Mode`, `.Match`, `.InputLock`, `.Register`) |
| `round/` | Glue over `jumbalaya_core.round` + store dispatch |
| `trade/` | The Trade marketplace offers and actions |
| `jumble/` | Glue over `jumbalaya_core.jumble` + live CardArea wiring |
| `jumble_play/` | Play evaluation (`play_jumble_word`); hand-clear orchestration |
| `cards/` | Letter-card definitions, `Card` class, `deck/` dealing |
| `perks/` | Glue over `jumbalaya_core` perk registry and effects |
| `feedback/` | Model-layer attention text queue (drained by `word_feedback`) |
| `persistence/` | Run save/restore (`run_save`), profile progress writes |

### Cards (`word_game/model/cards/`)

| File/package | Purpose |
|------|---------|
| `definitions.lua` | Letter-card and center definitions |
| `card.lua` | Runtime letter-card domain behavior |
| `card_ability.lua` | Card ability behavior |
| `deck/` | Deck construction, population, and dealing (uses `jumbalaya_core.cards.*`) |

### UI (`word_game/ui/`)

`word_game/ui/` has **no root-level modules** — everything lives in subpackages below.

| Package | Purpose |
|---------|---------|
| `util/` | Stateless helpers: `colour`, `localize`, `number_format`, `roll`, `game_runtime` |
| `facade/` | Cross-package resolver — UI modules import model/board via `require("word_game.ui.facade")` |
| `cards/` | Letter card presentation: `tooltip`, `popups`, `visuals`, `ui`, `letter_faces`, `inspect` |
| `table/` | TABLE_BOARD coordinator and table chrome |
| `table/controls/` | Play/shuffle buttons |
| `feedback/` | Ephemeral copy and FX |
| `tutorial/` | First-play onboarding |
| `layout/` | TABLE_BOARD geometry |
| `sidebar/` | Right-hand HUD |
| `score_banner/` | Jumble score chips, stage label, boss announce |
| `play_effects/` | Play cinematics + `resolution` |
| `perks/` | Bonus stack, discard bin, timeline timer, stamp UI |
| `trade/` | Marketplace overlay |
| `menu/` | Main menu + title logo |
| `overlays/` | Options, settings, results |
| `widgets/` | Shared controls + odometer |
| `callbacks/` | `Funcs.register` installers (`table_controls`, `trade`, `placement`, `overlays`) |
| `views/` | Store-subscribed view components (Phase 6) |
| `cardarea/` | `CardArea` class |

### Board (`word_game/board/`)

| Path | Purpose |
|------|---------|
| `placement/table.lua` | Row host (`PlacementTable`); wires geometry, snap, shimmer |
| `placement/layout.lua` | Row width/height, screen position, alignment dispatch |
| `placement/snap.lua` | Shared drag helpers and jumble slot snap |
| `placement/shimmer.lua` | Lock-in outline FX around placed cards |
| `placement/config.lua` | Row tunables (spacing, boss gap, shimmer duration) |
| `jumble/geometry.lua` | Span/fixed screen geometry, puzzle row width, card alignment |
| `bonus/gutter.lua` | Bonus stack layout and drag/snap hit tests |

### Integration hooks

| File | Hook |
|------|------|
| `app/core/session/loop.lua` | Engine frame + state dispatch; delegates TABLE_BOARD to `WORD_GAME_UI.TableBoard` |
| `app/startup.lua` | Thin orchestrator; `startup/profile`, `window`, `dealing` |
| `word_game/ui/callbacks/placement.lua` | `play_placement_word` → `controls/placement.try_play` |

### Play resolution split

| Layer | Module | Role |
|-------|--------|------|
| Core rule | `jumbalaya_core/rules/play.lua` | Pure play evaluation |
| Model glue | `jumble_play/jumble.lua` | `play_jumble_word()` → evaluation result on live state |
| UI | `play_effects/resolution.lua` | `resolve(Play)` → banners, fly, hand clear |
| UI | `table/controls/placement.lua` | Play button entry point |

Tests that need rules only call `jumbalaya_core` or `play_jumble_word`; tests that need full FX call `play_effects/resolution.resolve`.

### Score feedback roles

| Layer | Module | When to use |
|-------|--------|-------------|
| Persistent HUD | `score_banner/` | Rolling points × multiplier chips and “Points to get” |
| Ephemeral sentences | `word_feedback.lua` | Immediate board messages during play |
| Model queue | `model/feedback.lua` | Rules/model code that must not import UI |
| Play cinematics | `play_effects/` | Full play resolution FX |
| Per-card popups | `float_up_text.lua` | Short +2 / +mult rises from individual cards |

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

Application callbacks belong in `app`; gameplay actions belong in `word_game/ui` and delegate rules to `jumbalaya_core` via `word_game/model` glue.

---

## Naming

- Files, directories, locals, and functions: `snake_case`.
- Classes and exported module names: `PascalCase`.
- Existing package globals: `UPPER_SNAKE_CASE` (`WORD_GAME`, `DEVTOOLS`).
- Config files contain data and simple lookups, not runtime orchestration.
- Model glue files wire domain behavior to the runtime shell; they do not own rendering.
- UI files own drawing, layout, animation, and input presentation.

---

## File size and cohesion

Aim for 100–250 lines per implementation file. At 300 lines, review whether the file contains multiple responsibilities.

Reasonable exceptions: generated data, localization tables, `types/`, cohesive inherited runtime classes, and split jumble modules.

---

## Dependency rules

`app/bootstrap.lua` is the single authoritative load order. Bootstrap is orchestrated by `app/bootstrap/engine_adapter.lua`:

```text
engine_boot → runtime_boot (Game(), store, facade) → store_boot → presentation_boot
```

`Game()` is constructed in `runtime_boot.lua`; `app/runtime.lua` delegates to `jumbalaya-engine.shell`. There is no global `G` singleton.

The inheritance order is contractual:

```text
Object → Node → EaseNode/AnimNode → Sprite, Card, CardArea, RetainedPanel
```

Additional rules:

- `jumbalaya_core` never imports `app/`, `word_game/`, or Love2D.
- `word_game/model/` may import `jumbalaya_core` and `app/runtime`; never import `word_game/ui/` at module top level.
- `word_game/ui/` → `jumbalaya-engine` + `word_game/model` (facade) — never reverse.
- Prefer facade methods (`WORD_GAME.*`, `WORD_GAME_UI.*`) across package boundaries.
- Jumble snap/layout must not import UI modules; UI may import model/config.
- Two schedulers exist by design: engine tween lanes (`jumbalaya-engine`) and `jumbalaya-engine/effects/timeline_scheduler.lua` (timeline wrapper).

---

## Verification

```sh
love tests
emmylua_check . --severity warn   # CI blocks on errors only — see testing.md
```

Key test tiers:

- **Integration:** `test_jumble_play_flow.lua`, `test_save_roundtrip.lua`, `test_game_access.lua`
- **Core rules (no boot):** `test_core_jumble_rules.lua`, `test_core_play_evaluate.lua`, …
- **Callback catalog:** `test_g_funcs_registry.lua`

`tests/runner.lua` auto-discovers all `tests/unit/test_*.lua` files alphabetically.

---
