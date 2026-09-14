--[[ word_game/ui/cardarea/selection.lua - Card selection and highlight rules ]]

local game = require("word_game.ui.util.game_runtime").game
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx

local M = {}

local function type_handler(self, handlers)
	return handlers[self.config.type]
end

local function default_add_selection(self, card, silent)
	if #self.selected >= self.config.selected_limit then
		return
	end
	self.selected[#self.selected + 1] = card
	card:set_selected(true)
	if not silent then
		play_sfx("card_slide1")
	end
end

function M.can_select(self, card, handlers)
	local handler = type_handler(self, handlers)
	if handler and handler.can_select then
		return handler.can_select(self, card)
	end
	return false
end

function M.add_selection(self, card, silent, handlers)
	local handler = type_handler(self, handlers)
	if handler and handler.add_selection then
		return handler.add_selection(self, card, silent)
	end
	return default_add_selection(self, card, silent)
end

function M.remove_selection(self, card, force)
	if (not force) and card and card.ability.forced_selection and self == game().dealt_letters then
		return
	end
	for i = #self.selected, 1, -1 do
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
		local pinned_by_effect = self == game().dealt_letters and card.ability.forced_selection
		if not pinned_by_effect then
			card:set_selected(false)
			table.remove(self.selected, i)
		end
	end
end

return M
