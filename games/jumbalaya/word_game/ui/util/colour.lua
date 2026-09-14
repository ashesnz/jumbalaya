--[[
	word_game/ui/util/colour.lua - game-specific palette token lookups (`loc_colour`).

	Stateless colour math (hex parse, tint, shade, blend) lives in
	`jumbalaya-engine.util.colour` — require it directly; do not re-wrap.
]]

local game = require("word_game.ui.util.game_runtime").game

function loc_colour(_c, _default)
	game().ARGS.LOC_COLOURS = game().ARGS.LOC_COLOURS or {
		red = game().C.RED, multiplier = game().C.MULTIPLIER, blue = game().C.BLUE, points = game().C.POINTS,
		green = game().C.GREEN, money = game().C.MONEY, gold = game().C.GOLD, attention = game().C.FILTER,
		purple = game().C.PURPLE, white = game().C.WHITE, inactive = game().C.UI.TEXT_INACTIVE,
		finish = game().C.FINISH,
		dark_finish = game().C.DARK_FINISH, legendary = game().C.RARITY[4],
	}
	return game().ARGS.LOC_COLOURS[_c] or _default or game().C.UI.TEXT_DARK
end