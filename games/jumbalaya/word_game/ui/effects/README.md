# `word_game/ui/effects/` — runtime FX (motion & shaders)

**Not** play-button cinematics and **not** on-screen copy. Reusable **card/table motion** and **canvas juice** used across the table board.

| Module | Role |
|--------|------|
| `card_motion.lua` | Queued card moves (deal, snap, fly between piles) via timeline scheduler |
| `dissolve_fx.lua` | Shader dissolve/materialize on any node with a `dissolve` uniform |
| `easing.lua` | Shared easing helpers for UI tweens |
| `runtime.lua` | Canvas bounce / juice on the Game shell |
| `menu.lua` | Main-menu motion hooks |
| `status_text.lua` | Short-lived status strings on nodes |

**When to add code here:** a tween, shader, or pile-to-pile motion that multiple features might reuse.

**When not to:** full play resolution flow → `play_effects/`; sentences and popups → `feedback/`.

See also: [`play_effects/README.md`](../play_effects/README.md), [`feedback/README.md`](../feedback/README.md), [`docs/ui-stack.md`](../../../../docs/ui-stack.md).
