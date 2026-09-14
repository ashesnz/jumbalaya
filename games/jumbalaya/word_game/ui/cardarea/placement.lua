--[[
	word_game/ui/cardarea/placement.lua - Placement/jumble CardPile type behaviour.
]]

local game = require("word_game.ui.util.game_runtime").game
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx

local M = {}

function M.can_select(_self, _card)
	return not game().INPUT.HID.controller
end

function M.add_selection(self, card, silent)
	if #self.selected >= self.config.selected_limit then
		local oldest = self.selected[1]
		if oldest then self:remove_selection(oldest) end
	end
	self.selected[#self.selected+1] = card
	card:set_selected(true)
	if not silent then play_sfx('card_slide1') end
end

function M.on_remove_card(self, card)
	if game().pattern_row and game().pattern_row.area == self then
		game().pattern_row:on_remove_card(card)
	end
end

function M.on_remove(self)
	if game().pattern_row and game().pattern_row.area == self then
		game().pattern_row.area = nil
	end
end

function M.relayout(self)
	if self.config.type ~= 'placement' then return end
	if game().pattern_row and game().pattern_row.area == self then
		game().pattern_row:relayout()
	end
end

function M.draw_shadows(self)
	if self.config.type ~= 'placement' then return end
	if game().pattern_row and game().pattern_row.area == self then
		game().pattern_row:draw_shadows()
	end
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= 'placement' then return end
	for i = 1, #self.cards do
		if self.cards[i] ~= game().INPUT.focused.target then
			if not self.cards[i].selected then
				draw_card_layer(self.cards[i], v)
			end
		end
	end
	for i = 1, #self.cards do
		if self.cards[i] ~= game().INPUT.focused.target then
			if self.cards[i].selected then
				draw_card_layer(self.cards[i], v)
			end
		end
	end
end

return M
