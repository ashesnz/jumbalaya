# Glossary

Maps player-facing terms from [gameplay.md](gameplay.md) to code symbols and modules. When docs and UI disagree, **gameplay.md** is player truth; this file is **code truth**.

## Run snapshot (store)

Match progress lives on the **store snapshot** — read it via `game_access.get()`, `WORD_GAME.state()`, or `WORD_GAME.store():get()`. In the tables below, **`word_round.*`** and **`run_state.*`** refer to fields on that snapshot (see `types/store.lua`). Do not use `G.GAME`; the alias was removed.

## Run structure

| Term | Meaning | Code / state |
|------|---------|--------------|
| **Match** / **run** | Full roguelike attempt from menu to win or End Run | `G.STAGE == G.STAGES.RUN`; `Game:discard_run()` |
| **Set** | Group of hands (set 1 = 9 tutorial hands; sets 2–8 = 3 each) | `word_round.set` |
| **Hand** / **stage** | One scored round within a set (e.g. set 1 hand 3 → `1-3`) | `word_round.hand_index`; `round_config.hand_target(set, hand)` |
| **Showdown** | Third hand of sets 2–8 (higher target) | Same `hand_index == 3` in non-tutorial sets |
| **Target** | Score to reach on this hand | `word_round.target`; banner “Points to get” |

## Table layout

| Term | Meaning | Code / state |
|------|---------|--------------|
| **Hand** (cards) | Up to 7 letter cards you drag from | `G.dealt_letters` (CardPile); store pile `hand` |
| **Pattern row** / **placement row** | Fixed anchors + blank slots for the active puzzle | `G.pattern_row` (`PlacementTable`); store pile `pattern` |
| **Draw pile** / **deck pile** | Face-down stack you deal from | `G.draw_pile`; store pile `draw` |
| **Discard** / **recycle** | Cards returned after play or fly-off stash | `G.recycle_stash`; store pile `discard` |
| **Bonus gutter** | Side stack for boss-word bonus letter cards | `BonusStack` model; `WORD_GAME_UI.BonusStackUI` |
| **Sidebar** | Right HUD: stamps, deck art, End Run | `G.SIDEBAR_HUD`; `WORD_GAME_UI.Sidebar` |

## Jumble play

| Term | Meaning | Code / state |
|------|---------|--------------|
| **Jumble** / **jumble mode** | Active puzzle loop (pattern + hand + play) | `WORD_GAME.Jumble.is_active()`; `word_round.jumble` |
| **Puzzle** | One pattern configuration within a hand | `jumble.puzzle_index`; config `jumble_puzzle_{set}_{hand}.lua` |
| **Slots** | Blank or fixed letter positions in the pattern | `jumble.slots[]`; `slot.kind` = `blank` \| `fixed` \| `span` |
| **Bank** (puzzle) | Commit solved puzzle points × multiplier to stage total | `play_jumble_word` → `kind == "bank_puzzle"` |
| **Word play** | Submit letters currently in slots | `kind == "word_play"` |
| **Placement word** | Live preview string from slots (before Play) | `WORD_GAME.PlacementWord`; `placement_preview` in core |

## Score & time

| Term | Meaning | Code / state |
|------|---------|--------------|
| **Points** (puzzle) | Letter count on current puzzle | `jumble.puzzle_points` |
| **Multiplier** | +0.2× per extra word on same puzzle | `jumble.puzzle_multi` |
| **Banner** / **score HUD** | Chips showing points × mult and “to get” | `WORD_GAME_UI.ScoreBanner` |
| **Fuse** / **timeline** | 60s stage countdown bar | `WORD_GAME.Timeline`; `WORD_GAME_UI.TimelineTimer` |
| **Tokens** | Meta currency (set 1-1 fuse payout) | `run_state.tokens`; `TokenReward` fly FX |

## Controls & flows

| Term | Meaning | Code / state |
|------|---------|--------------|
| **Play** (button) | Submit word or bank puzzle | `play_placement_word` → `table/controls/placement.try_play` |
| **Shuffle** | Reorder cards in hand only | `shuffle_hand` |
| **Hold redraw** | Hold Play 5s to discard hand and deal 7 new cards | `WORD_GAME_UI.PlayHoldRedraw` |
| **The Trade** / **marketplace** | Between-hand shop | `WORD_GAME_UI.TradeUI`; `word_game/model/trade` |
| **Hand clear** | Target reached — celebration then shop or win | `play_effects/hand_clear`; `Play.on_hand_cleared` |
| **End Run** | Surrender from sidebar | `WORD_GAME.Match.end_run()` |

## FX packages (UI)

| Folder | Use for |
|--------|---------|
| `ui/effects/` | Reusable motion, dissolve, canvas juice |
| `ui/play_effects/` | Play-button cinematic pipeline |
| `ui/feedback/` | Copy, popups, confetti |

See [ui/effects/README.md](../games/jumbalaya/word_game/ui/effects/README.md) and siblings.

## Presentation bus

| Term | Meaning | Code |
|------|---------|------|
| **Presentation.emit** | Model → UI notification (one-way) | `word_game/model/presentation.lua`; catalog `types/presentation_events.lua` |
| **Layout refresh** | Deferred TABLE_BOARD relayout | `LayoutRequest.refresh()` → `ARGS.pending_layout` |
