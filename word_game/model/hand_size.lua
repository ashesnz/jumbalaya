--[[ word_game/model/hand_size.lua - Runtime jumble hand size (base + perk bonus) ]]

local dimensions = require("word_game.config.layout.dimensions")
local perk_effects = require("word_game.model.perks.effects")

local M = {}

function M.get()
	local base = dimensions.layout.TABLE_HAND_SIZE
	if G and G.TABLE_HAND_SIZE then
		base = G.TABLE_HAND_SIZE
	end
	return base + perk_effects.hand_size_bonus()
end

return M
