--[[
	word_game/ui/cardarea/placement.lua - Placement/jumble CardPile type behaviour.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local M = {}

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
	if runtime().pattern_row and runtime().pattern_row.area == self then
		runtime().pattern_row:on_remove_card(card)
	end
end

function M.on_remove(self)
	if runtime().pattern_row and runtime().pattern_row.area == self then
		runtime().pattern_row.area = nil
	end
end

function M.relayout(self)
	if self.config.type ~= 'placement' then return end
	if runtime().pattern_row and runtime().pattern_row.area == self then
		runtime().pattern_row:relayout()
	end
end

function M.draw_shadows(self)
	if self.config.type ~= 'placement' then return end
	if runtime().pattern_row and runtime().pattern_row.area == self then
		runtime().pattern_row:draw_shadows()
	end
end

local function store_renders_pattern()
	local board = WORD_GAME_UI and WORD_GAME_UI.TableBoard
	local view = board and board.table_board_view and board.table_board_view()
	return view and view:should_render_pattern_from_store()
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= 'placement' then return end
	if store_renders_pattern() then return end
	for i = 1, #self.cards do
		if self.cards[i] ~= runtime().INPUT.focused.target then
			if not self.cards[i].selected then
				draw_card_layer(self.cards[i], v)
			end
		end
	end
	for i = 1, #self.cards do
		if self.cards[i] ~= runtime().INPUT.focused.target then
			if self.cards[i].selected then
				draw_card_layer(self.cards[i], v)
			end
		end
	end
end

return M
