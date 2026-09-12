--[[
	word_game/model/hand_size.lua - Effective jumble hand size from dimensions plus wide_hand perk

	Core: jumbalaya_core.rules.hand_size
	Store: none
	Presentation: none
]]

local live_game = require("word_game.model.live_game")

local dimensions = require("word_game.config.layout.dimensions")
local perk_effects = require("word_game.model.perks.effects")
local core_hand_size = require("jumbalaya_core.rules.hand_size")

local M = {}

function M.get()
	local base = dimensions.layout.TABLE_HAND_SIZE
	if live_game() and live_game().TABLE_HAND_SIZE then
		base = live_game().TABLE_HAND_SIZE
	end
	return core_hand_size.get(base, { wide_hand = perk_effects.has("wide_hand") })
end

return M
