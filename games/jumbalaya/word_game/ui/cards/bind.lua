--[[ word_game/ui/cards/bind.lua - Mix Card presentation methods after model Card loads ]]

local M = {}

local installed = false

function M.install()
	if installed then return end
	installed = true
	require "word_game.ui.cards.visuals"
	require "word_game.ui.cards.ui"
end

return M
