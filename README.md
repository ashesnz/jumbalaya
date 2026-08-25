# Jumbalaya

Roguelike **jumble** word game built on Love2D — pattern puzzles, multiplier scoring, timeline pressure, tokens, and vouchers.

## Documentation

Player and design docs: **[docs/](docs/README.md)** — jumble gameplay, scoring, progression, systems, code map.

## Milo intro tutorial

Milo’s table-board intro can be skipped while developing.

In `word_game/config/characters.lua`:

```lua
-- Dev: skip Milo's table-board intro. Set to false to play it.
M.SKIP_INTRO = true
```

| Value | Effect |
|-------|--------|
| `true` | Skip the intro and start a normal hand |
| `false` | Play Milo’s intro on a fresh run |

Restart the game after changing the flag.
