---
name: jumbalaya
description: >-
  Work on the Jumbalaya Love2D/Lua jumble word game: package boundaries,
  sidebar HUD, jumble model/UI split, tests, and refactors. Use when editing
  word_game/, app/, tests/, or when the user asks about project structure,
  sidebar, layout, or jumble gameplay code.
---

# Jumbalaya project skill

## When to use

- Editing gameplay, UI, layout, or tests under `word_game/` or `app/`
- Refactoring packages or renaming modules
- Adding features to TABLE_BOARD, sidebar, perks, trade, or jumble play flow
- Answering questions about where code belongs

## Read first

1. `docs/code-organization.md` — package map and dependency rules
2. `docs/gameplay.md` — player-facing systems
3. `AGENTS.md` — agent-specific constraints and current structure
4. `.cursor/rules/jumbalaya-*.mdc` — always-on and glob-scoped rules

## Package boundaries

```text
app/core/          Engine: G, Card, LayoutView, input, audio, persistence
word_game/config/  Static tuning — boot/, layout/, visuals/, gameplay/, perks/, jumble/
word_game/model/   Rules and state — no root modules; use run/, round/, jumble/, etc.
word_game/board/   Row snap/geometry — placement/, jumble/, bonus/ (no UI imports at require time)
word_game/ui/      Presentation — may import model/config
```

### `word_game/ui/` subpackages (no root-level modules — use these paths)

| Path | Role |
|------|------|
| `ui/lib/` | `colour`, `localize`, `number_format`, `roll` |
| `ui/cards/` | Card tooltip, popups, visuals, inspect |
| `ui/table/` | `board`, `deck`, `placement_controls`, `stage_label`, `token_reward` |
| `ui/feedback/` | `word_feedback`, `float_up_text`, `confetti` |
| `ui/tutorial/` | `first_play`, `character_speech`, `hand_clear_focus` |
| `ui/play_effects/` | `resolution`, `card_fly_off`, play FX |
| `ui/sidebar/` | Right-hand HUD |
| `ui/layout/`, `ui/hand_shuffle/`, `ui/score_banner/`, `ui/perks/`, etc. | As named |

Cross-package: `WORD_GAME` facade in `word_game/init.lua`. Tests and `app/` should use the facade, not deep `word_game.model.*` requires unless testing internals.

## Sidebar (right-hand HUD)

All right-column HUD code lives in `word_game/ui/sidebar/`. Use **sidebar** naming everywhere:

| Concept | Location / symbol |
|---------|-------------------|
| Package | `word_game/ui/sidebar/` |
| Facade | `WORD_GAME.Sidebar` (instance from `word_game/ui/sidebar/init.lua`) |
| HUD global | `G.SIDEBAR_HUD` |
| Attach node | `G.SIDEBAR_ATTACH` |
| Column geometry | `WORD_GAME.Layout.sidebar_rect`, `sidebar_height`, `update_sidebar_attach` (implemented in `sidebar/layout.lua`, re-exported via `layout/init.lua`) |
| End Run button | `WORD_GAME.SidebarStageButton` in `sidebar/stage_button.lua` |
| G.FUNCS | `end_run_from_sidebar`, `ensure_table_board_sidebar` in `sidebar/funcs.lua` |

Do **not** use vault naming (`G.VAULT_HUD`, `VaultStageButton`, `layout/vault.lua`, etc.).

## TABLE_BOARD layout

| Module | Role |
|--------|------|
| `ui/layout/felt.lua` | Play column, felt rect, HUD metrics, `sidebar_right_x` |
| `ui/sidebar/layout.lua` | Sidebar column, deck slot, end-run slot rects |
| `ui/layout/placement.lua` | Screen positions, portrait/banner rects |
| `ui/layout/request.lua` | Deferred `Layout.request_refresh()` flag |

Model code calls `Layout.request_refresh()` — never sets sidebar attach positions directly.

## Jumble play flow

1. `placement_controls.try_play` → `play_resolution.resolve`
2. `jumble_play.play_jumble_word` — model evaluation (headless-testable)
3. `play_effects` — banners, fly, hand clear
4. `round.lua` / `jumble/` — hand advance, targets, boss words

## Adding tests

```sh
love tests
```

- New file: `tests/unit/test_<feature>.lua` (auto-discovered)
- Start with `mock_env.reset_game()` in `describe`
- Use `mock_env.ensure_engine_globals()` when real `Card`/`Sprite` classes are needed
- Sidebar button tests: `tests/unit/test_sidebar_stage_button.lua`

## Refactor checklist

1. Keep `G.FUNCS` string names stable unless updating all UI definitions that reference them
2. Re-export geometry on `WORD_GAME.Layout` if moving sidebar layout helpers
3. Update `word_game/init.lua` facade exports when adding cross-package APIs
4. Run `love tests` and `emmylua_check . --severity warn` for structural changes
5. Update `docs/code-organization.md` when package layout changes materially

## Avoid

- Extending legacy AP/plays/discards unless explicitly requested
- Importing UI from `word_game/model/` or `word_game/board/`
- Re-adding character portraits, achievements, edition badges, or vault terminology
- Editing `AlphaCardsBackup/`, `dictionary/words_set.lua`, or binary assets by hand
