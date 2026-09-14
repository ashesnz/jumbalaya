--[[ word_game/ui/cardarea/shop.lua - Shop, usable, and title_2 CardPile behaviour ]]

local game = require("word_game.ui.util.game_runtime").game
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx

local M = {}

local SHOP_TYPES = {
	shop = true,
	usable = true,
	title_2 = true,
}

local function is_shop_type(area)
	return SHOP_TYPES[area.config.type]
end

function M.can_select(self, _card)
	if game().INPUT.HID.controller then
		return false
	end
	if self.config.type == "shop" then
		return self.config.selected_limit > 0
	end
	if self.config.type == "usable" then
		return true
	end
	return false
end

function M.add_selection(self, card, silent)
	if self.config.type == "shop" then
		if self.selected[1] then
			self:remove_selection(self.selected[1])
		end
	elseif self.config.type == "usable" then
		if #self.selected >= self.config.selected_limit then
			self:remove_selection(self.selected[1])
		end
	elseif #self.selected >= self.config.selected_limit then
		return
	end
	self.selected[#self.selected + 1] = card
	card:set_selected(true)
	if not silent then
		play_sfx("card_slide1")
	end
end

function M.set_card_ranks(_self, _k, card)
	card.states.drag.can = false
end

local function draw_unselected_then_selected(self, v, draw_card_layer)
	for i = 1, #self.cards do
		local card = self.cards[i]
		if card ~= game().INPUT.focused.target and not card.selected then
			draw_card_layer(card, v)
		end
	end
	for i = 1, #self.cards do
		local card = self.cards[i]
		if card ~= game().INPUT.focused.target and card.selected then
			draw_card_layer(card, v)
		end
	end
end

function M.draw_layer(self, v, draw_card_layer)
	if not is_shop_type(self) then return end
	draw_unselected_then_selected(self, v, draw_card_layer)
end

function M.remove_target(self, candidates, card)
	if card == nil then
		return candidates[1]
	end
	return card
end

return M
