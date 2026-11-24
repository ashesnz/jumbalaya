# Jumbalaya

Roguelike **jumble** word game built on Love2D — pattern puzzles, multiplier scoring, timeline pressure, tokens, and perk stamps.

## Run the game and tests

Install [Love2D](https://love2d.org/) first, then run these commands from the repository root:

```bash
love games/jumbalaya
```

To run the test suite:

```bash
love tests
```

See [docs/testing.md](docs/testing.md) for more about the test suite.

## Documentation

Player and design docs: **[docs/](docs/README.md)** — jumble gameplay, scoring, progression, systems, code map.

AI / agent context: **[AGENTS.md](AGENTS.md)** and **[.cursor/skills/jumbalaya/SKILL.md](.cursor/skills/jumbalaya/SKILL.md)**.

Ticket workflow: **[docs/ticket-lifecycle.md](docs/ticket-lifecycle.md)** — readiness gate, individually callable specialists, and the end-to-end `/run-ticket` process.

## Skip tutorial

The first-play welcome tutorial can be skipped while developing.

Set `SKIP_TUTORIAL` in your shell or in a local `.env` file (copy from [`.env.example`](.env.example)). Shell environment variables take precedence over `.env`.

```bash
SKIP_TUTORIAL=1 love games/jumbalaya
```

Root shims (`love .`, `love tests`) still work during transition.

Or in `.env`:

```env
SKIP_TUTORIAL=1
```

| Value | Effect |
|-------|--------|
| `1`, `true`, `yes`, `on` | Skip the tutorial |
| unset / `0` / `false` | Show the tutorial for new players |

Restart the game after changing the flag.
