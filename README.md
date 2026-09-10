# Jumbalaya

Roguelike **jumble** word game built on Love2D — pattern puzzles, multiplier scoring, timeline pressure, tokens, and vouchers.

## Documentation

Player and design docs: **[docs/](docs/README.md)** — jumble gameplay, scoring, progression, systems, code map.

AI / agent context: **[AGENTS.md](AGENTS.md)** and **[.cursor/skills/jumbalaya/SKILL.md](.cursor/skills/jumbalaya/SKILL.md)**.

## Skip tutorial

The first-play welcome tutorial can be skipped while developing.

Set `SKIP_TUTORIAL` in your shell or in a local `.env` file (copy from [`.env.example`](.env.example)). Shell environment variables take precedence over `.env`.

```bash
SKIP_TUTORIAL=1 love .
```

Or in `.env`:

```env
SKIP_TUTORIAL=1
```

| Value | Effect |
|-------|--------|
| `1`, `true`, `yes`, `on` | Skip the tutorial |
| unset / `0` / `false` | Show the tutorial for new players |

Restart the game after changing the flag.
