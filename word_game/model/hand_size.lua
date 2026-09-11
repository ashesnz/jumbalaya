--[[ word_game/model/hand_size.lua - Runtime jumble hand size (base + perk bonus) ]]

local dimensions = require("word_game.config.layout.dimensions")
local perk_effects = require("word_game.model.perks.effects")
local core_hand_size = require("jumbalaya_core.rules.hand_size")

local M = {}

function M.get()
	local base = dimensions.layout.TABLE_HAND_SIZE
	if G and G.TABLE_HAND_SIZE then
		base = G.TABLE_HAND_SIZE
	end
	return core_hand_size.get(base, { wide_hand = perk_effects.has("wide_hand") })
end

return M
