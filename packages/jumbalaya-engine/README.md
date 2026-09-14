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

## Frame loop

`packages/jumbalaya-engine/session/loop.lua` owns the Love2D tick. Engine hooks
register through `session/updaters.lua` phases (loaded from `frame_updaters.lua`):

| Phase | Examples |
|-------|----------|
| `early_frame` | `mix_audio`, wall-clock timers, canvas juice |
| `simulation` | Ambient colour tweens, engine `TIMELINE:advance` |
| `early_board` / `late_board` | Table HUD, fuse bar, controls (registered in `runtime_boot.lua`) |
| `post_input` | Steam stat flush, save queue, card inspect |

Game-specific updaters belong in `app/bootstrap/runtime_boot.lua`, not in `loop.lua`.

### Transform registry

- `game().TRANSFORMS` is a dense array compacted each frame (`Tables.compact_array`).
- Both move and update iterate with `ipairs` only (never `pairs` on arrays).
- `AnimNode:remove` and `Node:remove` use `Tables.remove_swap_last` (O(1)).
- Move skips nodes already transformed this frame (`FRAME.TRANSFORM` gate).
- Update skips stationary majors still using the default empty `Node:update`.

### Scene draw roots

`game().SCENE_ROOTS` lists live nodes with no parent (registered from
`scene/roots.lua` when nodes join `LIVE.NODE` / `LIVE.TRANSFORM`).
`Game:render_scene_pass` draws via `ipairs(SCENE_ROOTS)` instead of scanning
sparse `LIVE.NODE` / `LIVE.TRANSFORM` with `pairs()`.

When reparenting scene nodes, call `node:set_scene_parent(parent)` (or
`SceneRoots.set_parent`) so the root list stays accurate.
