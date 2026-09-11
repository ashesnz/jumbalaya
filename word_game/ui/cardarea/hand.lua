--[[
	word_game/ui/cardarea/hand.lua - Hand CardArea type behaviour.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")

local M = {}

local function table_board()
	return runtime().STATE == runtime().STATES.TABLE_BOARD
end

function M.relayout(self)
	if self.config.type ~= 'hand' then return end

	if table_board() then
		local n = #self.cards
		local spacing = runtime().HAND_CARD_SPACING or 0.78
		local card_w = self.card_w or runtime().CARD_W
		local group_w = card_w + math.max(n - 1, 0) * card_w * spacing
		local start_x = self.T.x + (self.T.w - group_w) / 2
		local fan_n = facade.hand_size().get()
		for k, card in ipairs(self.cards) do
			if not card.states.drag.is and not card.shuffle_hop and not card.placement_recall_slide then
				local slot = k + (fan_n - n) * 0.5
				card.T.r = 0.2 * (-fan_n / 2 - 0.5 + slot) / fan_n + 0.02 * math.sin(2 * runtime().TIMERS.REAL + card.T.x)
				card.T.x = start_x + (k - 1) * card_w * spacing + 0.5 * (card_w - card.T.w)
				card.T.y = self.T.y + self.T.h / 2 - card.T.h / 2 + 0.03 * math.sin(0.666 * runtime().TIMERS.REAL + card.T.x) + math.abs(0.5 * (-fan_n / 2 + slot - 0.5) / fan_n) - 0.2
				card.T.x = card.T.x + card.shadow_parallax.x / 30
			end
		end
		table.sort(self.cards, function(a, b) return a.T.x + a.T.w / 2 < b.T.x + b.T.w / 2 end)
	end
end

local function store_renders_hand()
	local board = WORD_GAME_UI and WORD_GAME_UI.TableBoard
	local view = board and board.table_board_view and board.table_board_view()
	return view and view:should_render_hand_from_store()
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= 'hand' then return end
	if store_renders_hand() then return end
	local resting, hopping = {}, {}
	for i = 1, #self.cards do
		local card = self.cards[i]
		if card.shuffle_hop or card.placement_recall_slide then
			hopping[#hopping + 1] = card
		else
			resting[#resting + 1] = card
		end
	end
	local function by_x(a, b)
		return a.T.x + a.T.w / 2 < b.T.x + b.T.w / 2
	end
	table.sort(resting, by_x)
	table.sort(hopping, by_x)
	local function draw_card(card)
		if card ~= runtime().INPUT.focused.target or self == runtime().dealt_letters then
			draw_card_layer(card, v)
		end
	end
	for _, card in ipairs(resting) do
		draw_card(card)
	end
	for _, card in ipairs(hopping) do
		draw_card(card)
	end
end

return M
