--[[
	word_game/ui/layout/init.lua - TABLE_BOARD geometry facade.

	Positions are fractions of the room (same idea as Dice Have No Eyes'
	display:dimensions_scaled() * 0.5, 0.17), so HUD / felt / sidebar stay
	aligned when the window resizes. TILESCALE still maps tiles to pixels.
	Sidebar column geometry lives in word_game/ui/sidebar/layout.lua.
]]

local felt = require("word_game.ui.layout.felt")
local sidebar_layout = require("word_game.ui.sidebar.layout")
local placement = require("word_game.ui.layout.placement")
local request = require("word_game.ui.layout.request")
local backgrounds = require("word_game.ui.layout.backgrounds")

local M = {}

for k, v in pairs(felt) do
	M[k] = v
end
for k, v in pairs(sidebar_layout) do
	M[k] = v
end
for k, v in pairs(placement) do
	M[k] = v
end

M.request_refresh = request.refresh

function M.run_backgrounds()
	backgrounds.run()
	request.refresh()
end

return M
