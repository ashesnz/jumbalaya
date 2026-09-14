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
obvious. UI code uses the parallel helper
`require("word_game.ui.util.game_runtime").game`.

## Kind graph globals

`Node`, `AnimNode`, `EaseNode`, and derived types (`Card`, `CardPile`, …) are
assigned to `_G` because the Kind metatable graph and UIBox class checks expect
global names. New presentation types should be closed `local M` modules unless
they must participate in that graph — register them in boot, not scattered
`:derive` assignments.
