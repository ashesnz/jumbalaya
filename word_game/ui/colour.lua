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
    spades = G.C.BLACK, hearts = G.C.RED, clubs = G.C.BLACK, diamonds = G.C.RED,
    orbit = G.C.SECONDARY_SET.Orbit,
    phantom = G.C.SECONDARY_SET.Phantom, finish = G.C.FINISH,
    dark_finish = G.C.DARK_FINISH, legendary = G.C.RARITY[4],
    enhanced = G.C.SECONDARY_SET.Enhanced
  }
  return G.ARGS.LOC_COLOURS[_c] or _default or G.C.UI.TEXT_DARK
end

function get_stake_col(_stake)
  G.C.STAKES = G.C.STAKES or {G.C.WHITE, G.C.RED, G.C.GREEN, G.C.BLACK, G.C.BLUE, G.C.PURPLE, G.C.ORANGE, G.C.GOLD}
  return G.C.STAKES[_stake]
end