# jumbalaya-engine

Custom Love2D engine layer (scene graph, panels, input, graphics, sound).

## Live game access (cycle breaker)

Engine modules must not import `app/` or `word_game/`. The shell holds the bound
`Game` instance injected at boot (`app/bootstrap/shell_bind.lua`).

**Use the shell function reference — do not add a local wrapper in every file:**

```lua
local shell = require("jumbalaya-engine.shell")
local game = shell.game

-- call sites
if game() and game().ROOM then ...
```

Avoid:

```lua
local function g() return shell.game() end  -- noisy; duplicates in ~60 files
```

The lazy call `game()` keeps require-time cycles safe while making the accessor
obvious.

Parallel accessors (same function reference, no per-file wrapper):

| Layer | Pattern |
|-------|---------|
| `word_game/ui/` | `local game = require("word_game.ui.util.game_runtime").game` |
| `app/`, `word_game/board/` | `local game = require("app.runtime").game` |

When a function parameter is already named `game`, name the accessor `runtime`
instead to avoid shadowing (see `word_game/ui/table/board.lua`).

## Kind graph globals

Engine and gameplay `:derive` classes are **local module exports**. Boot assigns
`_G` aliases once:

- `jumbalaya-engine/boot.lua` → `require("jumbalaya-engine.globals").install()`
- `app/bootstrap/kind_globals.lua` → `Game`, `Card`, `CardPile`, `TitleLogo`, …

New types that must participate in the Kind metatable graph (`getmetatable(x) == Card`)
should be added to the appropriate install table — not assigned at the bottom of
random modules.

UI-only closed classes (e.g. `FloatUpText`, `Odometer`) can stay module-local when
nothing checks the global name.
