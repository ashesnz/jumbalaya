# `word_game/ui/play_effects/` — play cinematics

Orchestration for **pressing Play**: model returns a result; these modules run the **multi-step cinematic** (banners, card fly-off, hand clear, boss intro, puzzle advance).

| Module | Role |
|--------|------|
| `resolution.lua` | Entry: `resolve(Play)` after `play_jumble_word` |
| `animate.lua` | Timed sequences (puzzle advance, boss success, card choreography) |
| `definition.lua` | Shared flags, banner hooks, hand-control sync |
| `hand_clear.lua` | Stage-clear celebration + `Play.on_hand_cleared` wiring |
| `boss_word_intro.lua` | 3-2-1 countdown and boss-hand deal |
| `card_fly_off.lua` | Played cards fly off / stash for recycle |

**When to add code here:** a new beat in the play → score → clear → marketplace pipeline.

**When not to:** generic card motion → `effects/card_motion.lua`; one-line invalid-word text → `feedback/word_feedback.lua`.

Tests that need rules only call `play_jumble_word`; tests that need full FX call `play_effects/resolution.resolve`.
