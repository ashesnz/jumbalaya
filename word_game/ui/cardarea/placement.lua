--[[
	word_game/ui/cardarea/placement.lua - Placement/jumble CardArea type behaviour.
]]

local M = {}

function M.set_card_ranks(self, k, card)
	card.states.drag.can = true
end

function M.can_select(self, card)
	if G.INPUT.HID.controller then
		return false
	end
	return true
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
	if G.placement_table and G.placement_table.area == self then
		G.placement_table:on_remove_card(card)
	end
end

function M.on_remove(self)
	if G.placement_table and G.placement_table.area == self then
		G.placement_table.area = nil
	end
end

function M.relayout(self)
	if self.config.type ~= 'placement' then return end
	if G.placement_table and G.placement_table.area == self then
		G.placement_table:relayout()
	end
end

function M.draw_shadows(self)
	if self.config.type ~= 'placement' then return end
	if G.placement_table and G.placement_table.area == self then
		G.placement_table:draw_shadows()
	end
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= 'placement' then return end
	for i = 1, #self.cards do
		if self.cards[i] ~= G.INPUT.focused.target then
			if not self.cards[i].selected then
				draw_card_layer(self.cards[i], v)
			end
		end
	end
	for i = 1, #self.cards do
		if self.cards[i] ~= G.INPUT.focused.target then
			if self.cards[i].selected then
				draw_card_layer(self.cards[i], v)
			end
		end
	end
end

return M
