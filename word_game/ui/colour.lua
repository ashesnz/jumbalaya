--[[
  word_game/ui/colour.lua - game-specific colour lookups.

  Engine-level helpers (HEX, mix_colours, lighten, darken, adjust_alpha)
  live in app/runtime/colour.lua and are installed as globals from there.
]]

function loc_colour(_c, _default)
  G.ARGS.LOC_COLOURS = G.ARGS.LOC_COLOURS or {
    red = G.C.RED, multiplier = G.C.MULTIPLIER, blue = G.C.BLUE, points = G.C.POINTS,
    green = G.C.GREEN, money = G.C.MONEY, gold = G.C.GOLD, attention = G.C.FILTER,
    purple = G.C.PURPLE, white = G.C.WHITE, inactive = G.C.UI.TEXT_INACTIVE,
    finish = G.C.FINISH,
    dark_finish = G.C.DARK_FINISH, legendary = G.C.RARITY[4],
  }
  return G.ARGS.LOC_COLOURS[_c] or _default or G.C.UI.TEXT_DARK
end