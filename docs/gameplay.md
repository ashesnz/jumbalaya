# Gameplay

Jumbalaya is a roguelike **jumble** word game: pattern puzzles, a **points × multiplier** score banner, a burning **timeline fuse**, **tokens**, and **perks**.

**Goal:** On each stage, bank enough cumulative score to meet the hand **target**, then move on. Clear set 8’s Showdown to win the match.

---

## Match structure

A **match** (run) is a sequence of **sets**. Each set has exactly **3 hands**:

| Hand index | Type | Label |
|-----------:|------|-------|
| 1 | Standard | Standard Hand |
| 2 | Standard | Standard Hand |
| 3 | Showdown | Showdown Hand |

- **Win** by clearing the Showdown on **set 8**.
- Progress is shown as **set-hand** (e.g. `1-3` = set 1, showdown).

Every stage in sets 1–8 runs in **jumble mode** (`word_game/model/jumble.lua` → `is_active_hand`).

### Hand targets

Each stage has a score **target**. Banked puzzle totals must reach or exceed it.

| Set | Hand 1 | Hand 2 | Showdown |
|----:|-------:|-------:|---------:|
| 1 | 20 | 40 | 50 |
| 2 | 100 | 140 | 175 |
| 3 | 200 | 280 | 350 |
| 4 | 400 | 560 | 700 |
| 5 | 800 | 1,120 | 1,400 |
| 6 | 1,600 | 2,240 | 2,800 |
| 7 | 3,200 | 4,480 | 5,600 |
| 8 | 6,400 | 8,960 | 11,200 |

From set 3 onward, each set **doubles** the previous row. Runs past set 8 keep doubling from the set 8 row (`round_config.hand_target`).

### Per-stage lifecycle

```
Start stage
    ↓
Load jumble puzzles for this set/hand (config/jumble_puzzle_{set}_{hand}.lua)
    ↓
Deal 7 cards from jumble deck (A, E, R, T, N, L, S)
    ↓
Reset timeline fuse to 60s (paused on perk showdown until shop closes)
    ↓
┌─────────────────────────────────────────────────────────────┐
│  Puzzle loop                                                │
│    • Drag letters into pattern slots                        │
│    • Play valid words → points + multiplier on banner       │
│    • Bank solved puzzle (Play with empty slots) → total     │
│    • Advance to next puzzle until target reached            │
│    • Shuffle / hold-Play redraw as needed                   │
└─────────────────────────────────────────────────────────────┘
    ↓
Target reached?  ──yes──→  Hand cleared
    ↓ no
Continue puzzles / redraw hand
```

When a new stage starts:

- Jumble state resets (`puzzle_index`, `total_score`, current puzzle points/multiplier).
- Timeline resets to **60 seconds** (except perk-hand pause — see below).
- After hand 1 or 2: same set, next hand index.
- After hand 3 (Showdown): next set, hand 1.

### After clearing a stage

1. Confetti and hand-clear celebration.
2. **Set 1, hand 1 only:** leftover timeline seconds convert to **tokens** (1 token per floored second) with a fly-in animation.
3. Branch:
   - **Final stage** (set 8 Showdown cleared) → match won screen.
   - Otherwise → **The Trade** (Card Marketplace) → next stage.

---

## The table board

During a stage you see:

- **Timeline fuse** — 60s countdown bar where Milo’s portrait used to be (`word_game/ui/timeline_timer.lua`). Burns green → red from the right. Cosmetic pressure; it does not end the run when it hits zero.
- **Pattern row** — fixed anchor letters plus slots you fill from your hand (`word_game/board/jumble_geometry.lua`, `word_game/ui/jumble_fixed_letters.lua`).
- **Your hand** — up to 7 letter cards at the bottom.
- **Shuffle button** (left of hand) — reshuffles cards already in your hand.
- **Play button** (right of hand) — submit a word or bank a solved puzzle; **hold 5 seconds** for a full-hand redraw.
- **Score banner** — current puzzle **points × multiplier** chips and **“N Points to get”** toward the stage target.
- **Draw pile** — jumble deck stack; shows remaining cards. Token pile stacks above it after you earn tokens.
- **Sidebar** — stage odometer, recent banks, perk name when selected.

The old **discard bin** is hidden during jumble hands. Drag-to-bin discards from the Scrabble loop are inactive.

---

## Jumble puzzles

Each stage loads one or more **patterns** from `word_game/config/jumble_puzzle_{set}_{hand}.lua`, routed by `word_game/config/jumble_puzzles.lua`.

### Pattern types

| Type | Config example | What you build |
|------|----------------|----------------|
| **Span** | `{ span = {"C","T"}, min=3, max=7 }` → display `C…T` | Word starts with C and ends with T |
| **Prefix** | `{ prefix = "C", min=3, max=7 }` | Word starts with C |
| **Suffix** | `{ suffix = "AR", min=3, max=7 }` | Word ends with AR |
| **Center** | `{ center = "T", min=3, max=7 }` | Word contains pinned center block |
| **Rigid** | `"C_T"` | Fixed letters at `_` blanks you fill |

**Fixed** letters render as non-draggable tiles. **Span/blank** slots accept cards from your hand. Snap and layout live under `word_game/board/snap.lua` and `word_game/board/jumble_geometry.lua`.

On hand deal, `ensure_playable_puzzle()` picks a solvable opening pattern when possible.

---

## Playing a puzzle

Press **Play** (`play_placement_word` → `Flow.play_jumble_word` when jumble is active).

### A) Submit a word (cards placed in slots)

1. Drag letters from hand into pattern slots.
2. Press **Play**.
3. Word must fit the pattern, be in the dictionary, and not repeat a word already played on this puzzle.
4. **Points** += letter count (`#word`). **Multiplier** rises by **+0.2×** for each additional word on the same puzzle (2nd word → 1.2×, 3rd → 1.4×, rounded to 0.1).
5. Used cards return to the deck; hand refills to 7.
6. Score banner animates points × multiplier and updates **“Points to get”**.
7. If projected banked total ≥ target → stage cleared.

### B) Bank a solved puzzle (no cards placed, puzzle marked solved)

When the puzzle is solved but slots are empty (already played words this puzzle):

1. Press **Play** with nothing placed.
2. Banks `floor(puzzle_points × puzzle_multi)` into the stage total.
3. If target reached → stage cleared; else → next puzzle (`Flow.jumble_next` with slide animation).

Pressing **Play** on an empty, unsolved puzzle shows **“Must play a word or skip entirely”**.

### Word rules

| Rule | Value |
|------|------:|
| Minimum length | 3 letters (unless pattern constrains more) |
| Maximum length | 7 letters (pattern `max`) |
| Dictionary | Offline word list (~40k English words) |
| Invalid word | Rejected with feedback; no bank |

---

## Scoring (jumble)

Jumble scoring replaces the old Scrabble **Alpha Points (AP)** letter table for normal play.

| Concept | Rule |
|---------|------|
| Word points | Letter count (`#word`) |
| Puzzle multiplier | `1.0 + (words_on_puzzle − 1) × 0.2`, rounded to 0.1 |
| Live banner total | `floor(puzzle_points × puzzle_multi)` |
| Stage target | `round_config.HAND_TARGETS[set][hand]` |
| Clear check | Banked cumulative score ≥ target |

The banner shows **points** and multiplier chips, plus centered **“N Points to get”** between the pattern row and hand.

---

## Hand controls

| Control | Action |
|---------|--------|
| **Shuffle** (↻, left) | Randomize letter order in your current hand (needs ≥2 cards) |
| **Play** (▶, right, tap) | Submit word or bank puzzle |
| **Play** (hold ~5s) | Yellow ring drains clockwise from 12 o’clock; entire hand slides off-screen; 7 new cards deal one at a time. Cards in pattern slots are recalled to hand first. |

Hold-to-redraw is independent of the old discard counter. It is blocked only during score/redraw animations.

---

## Timeline & tokens

### Timeline fuse

- **60 seconds** per stage, drawn as a mathematical fuse bar (`TimelineTimer.TOTAL_DURATION`).
- Countdown precision: whole seconds ≥10s, one decimal ≥5s, two decimals below 5s.
- Updates while the table board is active; **frozen** when set 1-1 clears for token payout.
- Does **not** currently fail the run at 0s. A separate jumble model timer (`config/jumble.lua`, 30s) exists but is **disabled** (`TIMER_ENABLED = false`).

### Tokens

- Earned on **set 1, hand 1 clear** only: `floor(time_remaining)` tokens added to your pile (`TokenReward`, `state.alpha.tokens`).
- Gold sticker sprites fly from the timeline into the token stack; counter rolls up.
- Hand-clear **spotlight** dims the table during the 1-1 reward sequence.
- Starting tokens: **0** (`economy.STARTING_TOKENS`).

---

## Perks (early showdowns)

On **sets 1–3, hand 3** (`round_config.is_perk_hand`):

1. Timeline stays paused until the shop closes.
2. **Perk marketplace** opens with **3 random offers** from `config/perks.lua`.
3. Each perk costs **10–100 tokens** (steps of 10), rolled per offer.
4. Purchase spends tokens with a reverse fly animation.
5. After picking (or skipping), timeline resets to 60s and play begins.

Most perk descriptions still reference the legacy AP system. Only **`extra_play`** and **`extra_redraw`** have wired effects today; others are stored on `G.GAME.selected_perk` for future hooks.

---

## Between stages

### The Vault

Tracks unique words across a match in legacy code. Jumble play logs puzzle banks to the sidebar instead of vault AP entries.

### The Trade (Card Marketplace)

Opens after every cleared stage except the winning one. **Free.**

| Stage type | Offer |
|------------|-------|
| Standard (×1, ×2) | Pick 1 of 2 letters from a random row, or Skip |
| Showdown (×3) | Separate **Add** and **Remove** rows; both must be resolved |

---

See [Code organization](code-organization.md) for file-level mapping.

---

## Debug tools (dev builds)

Non-release builds include a debug panel (Tab or **DBG** button):

- Jump to stages, type test words, view playable-word hints.
- Hint list accounts for **fixed puzzle letters** when suggesting words.

---

## Source of truth

| Topic | Primary files |
|-------|----------------|
| Jumble rules & puzzles | `word_game/model/jumble.lua`, `word_game/config/jumble_puzzle_*_*.lua` |
| Play / bank flow | `word_game/model/play/` |
| Hand limits & targets | `word_game/config/round_config.lua` |
| Jumble deck | `word_game/config/jumble.lua`, `word_game/model/deck/jumble.lua` |
| Pattern layout & snap | `word_game/board/jumble_geometry.lua`, `word_game/board/snap.lua` |
| Score banner | `word_game/ui/score_banner.lua` |
| Timeline & tokens | `word_game/ui/timeline_timer.lua`, `word_game/ui/token_reward.lua` |
| Perks | `word_game/config/perks.lua`, `word_game/ui/perk_market.lua` |
| Hand controls | `word_game/ui/hand_shuffle.lua`, `word_game/ui/play_hold_redraw.lua` |
| Match flow | `word_game/model/round.lua`, `word_game/ui/trade.lua` |
| Trade | `word_game/model/trade.lua` |
