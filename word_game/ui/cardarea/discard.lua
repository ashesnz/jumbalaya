--[[
	word_game/ui/cardarea/discard.lua - Discard pile CardArea behaviour.
]]

local table_discard = require("word_game.ui.table_discard")

local M = {}

function M.update(self, dt)
	if self ~= G.discard then return end
	if table_discard.uses_table_draw() then
		self.states.collide.can = true
		self.states.hover.can = true
		self.states.release_on.can = true
		table_discard.update(dt)
	else
		self.states.collide.can = false
		self.states.hover.can = false
		self.states.release_on.can = false
	end
	for _, card in ipairs(self.cards or {}) do
		if card.area == self then
			card.states.drag.can = false
			card.states.collide.can = false
			card.states.hover.can = false
			card.states.click.can = false
		end
	end
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= "discard" then return end
	if self == G.discard and table_discard.uses_table_draw() then
		if v == "card" then
			table_discard.draw(self)
		end
		for i = 1, #(self.cards or {}) do
			local card = self.cards[i]
			if card ~= G.INPUT.focused.target and math.abs(card.VT.x - self.T.x) > 0.4 then
				draw_card_layer(card, v)
			end
		end
	else
		for i = 1, #(self.cards or {}) do
			local card = self.cards[i]
			if card ~= G.INPUT.focused.target and math.abs(card.VT.x - self.T.x) > 1 then
				draw_card_layer(card, v)
			end
		end
	end
end

function M.release(self, dragged)
	if self ~= G.discard or not table_discard.uses_table_draw() then return end
	if not dragged or not dragged:is_kind(Card) then return end
	table_discard.try_discard(dragged)
end

return M
