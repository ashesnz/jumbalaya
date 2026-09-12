# `word_game/ui/feedback/` — copy & lightweight popups

**Readable text and small celebratory bursts** on the table — not full play cinematics and not low-level card motion.

| Module | Role |
|--------|------|
| `word_feedback.lua` | Full-sentence board messages (`spawn_attention`, classic proceed, invalid word) |
| `float_up_text.lua` | Per-card +points / +mult rises |
| `modifier_feedback.lua` | Letter-modifier callouts on the pattern row |
| `confetti.lua` | Hand-clear / stage-clear particle burst |
| `comic_burst.lua` | Comic-style emphasis burst |

**When to add code here:** player-facing copy, odometer-style popups, or short FX that do not own the play pipeline.

**Model queue:** `word_game/model/feedback.lua` queues messages for `word_feedback` — model must not import this package directly.

**When not to:** multi-second timed play sequences → `play_effects/`; card deal tweens → `effects/card_motion.lua`.
