--[[
	word_game/ui/layout/init.lua - TABLE_BOARD geometry facade.

	Positions are fractions of the room (same idea as Dice Have No Eyes'
	display:dimensions_scaled() * 0.5, 0.17), so HUD / felt / vault stay
	aligned when the window resizes. TILESCALE still maps tiles to pixels.
]]

local felt = require("word_game.ui.layout.felt")
local vault = require("word_game.ui.layout.vault")
local placement = require("word_game.ui.layout.placement")
local request = require("word_game.ui.layout.request")

local M = {}

for k, v in pairs(felt) do
	M[k] = v
end
for k, v in pairs(vault) do
	M[k] = v
end
for k, v in pairs(placement) do
	M[k] = v
end

M.request_refresh = request.refresh

return M
