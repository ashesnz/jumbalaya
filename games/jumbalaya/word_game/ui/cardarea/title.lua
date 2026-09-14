--[[ word_game/ui/cardarea/title.lua - Title and perk CardPile draw behaviour ]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

local TITLE_TYPES = {
	title = true,
	perk = true,
}

local function is_title_type(area)
	return TITLE_TYPES[area.config.type]
end

function M.draw_layer(self, v, draw_card_layer)
	if not is_title_type(self) then return end
	for i = 1, #self.cards do
		local card = self.cards[i]
		if card ~= game().INPUT.focused.target or self == game().dealt_letters then
			draw_card_layer(card, v)
		end
	end
end

return M
