--[[
  word_game/ui/colour.lua - game-specific colour lookups.

  Engine-level helpers (HEX, mix_colours, lighten, darken, adjust_alpha)
  live in app/runtime/colour.lua and are installed as globals from there.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

function loc_colour(_c, _default)
  runtime().ARGS.LOC_COLOURS = runtime().ARGS.LOC_COLOURS or {
    red = runtime().C.RED, multiplier = runtime().C.MULTIPLIER, blue = runtime().C.BLUE, points = runtime().C.POINTS,
    green = runtime().C.GREEN, money = runtime().C.MONEY, gold = runtime().C.GOLD, attention = runtime().C.FILTER,
    purple = runtime().C.PURPLE, white = runtime().C.WHITE, inactive = runtime().C.UI.TEXT_INACTIVE,
    finish = runtime().C.FINISH,
    dark_finish = runtime().C.DARK_FINISH, legendary = runtime().C.RARITY[4],
  }
  return runtime().ARGS.LOC_COLOURS[_c] or _default or runtime().C.UI.TEXT_DARK
end