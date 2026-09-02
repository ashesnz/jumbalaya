--[[ word_game/config/hand_size.lua - Authoritative jumble hand size ]]

local dimensions = require("word_game.config.dimensions")

local M = {}

function M.get()
	if G and G.TABLE_HAND_SIZE then
		return G.TABLE_HAND_SIZE
	end
	return dimensions.layout.TABLE_HAND_SIZE
end

return M
