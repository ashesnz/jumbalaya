--[[ word_game/ui/cardarea/selection.lua - Card selection and highlight rules ]]

local M = {}

local function type_handler(self, handlers)
	return handlers[self.config.type]
end

function M.can_select(self, card, handlers)
	local handler = type_handler(self, handlers)
	if handler and handler.can_select then
		if handler.can_select(self, card) then
			return true
		end
	end
	if G.INPUT.HID.controller then
		return false
	else
		if self.config.type == 'usable' or
			(self.config.type == 'shop' and self.config.selected_limit > 0)
		then
				return true
		end
	end
	return false
end

function M.add_selection(self, card, silent, handlers)
	local handler = type_handler(self, handlers)
	if handler and handler.add_selection then
		return handler.add_selection(self, card, silent)
	end

	if self.config.type == 'shop' then
		if self.selected[1] then self:remove_selection(self.selected[1]) end
	elseif self.config.type == 'usable' then
		if #self.selected >= self.config.selected_limit then
			self:remove_selection(self.selected[1])
		end
	elseif #self.selected >= self.config.selected_limit then
		return
	end

	self.selected[#self.selected + 1] = card
	card:set_selected(true)
	if not silent then play_sfx('card_slide1') end
end

function M.remove_selection(self, card, force)
	if (not force) and  card and card.ability.forced_selection and self == G.hand then return end
	for i = #self.selected,1,-1 do
		if self.selected[i] == card then
			table.remove(self.selected, i)
			break
		end
	end
	card:set_selected(false)
end

function M.clear_selection(self)
	for i = #self.selected, 1, -1 do
		local card = self.selected[i]
		local pinned_by_effect = self == G.hand and card.ability.forced_selection
		if not pinned_by_effect then
			card:set_selected(false)
			table.remove(self.selected, i)
		end
	end
end

return M
