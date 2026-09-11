--[[
	word_game/ui/cardarea/deck.lua - Deck CardPile type behaviour.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local M = {}

local function table_board()
	return runtime().STATE == runtime().STATES.TABLE_BOARD
end

local function face_down_in_pile(card)
	if table_board() then return end
	if card.facing == 'front' then
		card:flip()
	end
end

function M.set_card_ranks(self, k, card)
	if k > 1 then
		card.states.drag.can = false
		card.states.collide.can = false
	end
end

function M.relayout(self)
	if self.config.type ~= 'deck' then return end
	for i = #self.cards, 1, -1 do
		local owned = self.cards[i]
		if owned.area and owned.area ~= self then
			table.remove(self.cards, i)
		end
	end
	local deck_height = (self.config.deck_height or 0.15)/52
	for k, card in ipairs(self.cards) do
		face_down_in_pile(card)

		if not card.states.drag.is then
			card.T.x = self.T.x + 0.5*(self.T.w - card.T.w) + self.shadow_parallax.x*deck_height*(#self.cards/(self == runtime().draw_pile and 1 or 2) - k) + 0.9*self.shuffle_amt*(1 - k*0.01)*(k%2 == 1 and 1 or -0)
			card.T.y = self.T.y + 0.5*(self.T.h - card.T.h) + self.shadow_parallax.y*deck_height*(#self.cards/(self == runtime().draw_pile and 1 or 2) - k)
			card.T.r = 0 + 0.3*self.shuffle_amt*(1 + k*0.05)*(k%2 == 1 and 1 or -0)
			card.T.x = card.T.x + card.shadow_parallax.x/30
		end
	end
end

local function store_renders_draw()
	local board = WORD_GAME_UI and WORD_GAME_UI.TableBoard
	local view = board and board.table_board_view and board.table_board_view()
	return view and view:should_render_draw_from_store()
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= 'deck' then return end
	if self == runtime().draw_pile and store_renders_draw() then return end
	if self == runtime().draw_pile and WORD_GAME_UI.TableDeck
		and WORD_GAME_UI.TableDeck.uses_table_draw() then
		if v == 'card' then
			WORD_GAME_UI.TableDeck.draw(self)
		end
	else
		for i = #self.cards, 1, -1 do
			if self.cards[i] ~= runtime().INPUT.focused.target then
				if i == 1 or i%(self.config.thin_draw or 9) == 0 or i == #self.cards or math.abs(self.cards[i].VT.x - self.T.x) > 1 or math.abs(self.cards[i].VT.y - self.T.y) > 1  then
					draw_card_layer(self.cards[i], v)
				end
			end
		end
	end
end

function M.update(self, dt)
	if self ~= runtime().draw_pile then return end
	local table_deck = self == runtime().draw_pile and WORD_GAME_UI.TableDeck
		and WORD_GAME_UI.TableDeck.uses_table_draw()
	self.states.collide.can = not table_deck
	self.states.hover.can = not table_deck
	self.states.click.can = not table_deck
	if table_deck then
		self.states.collide.can = true
		self.states.hover.can = true
		self.states.click.can = true
		for _, card in ipairs(self.cards) do
			if card.area == self then
				card.states.collide.can = false
				card.states.hover.can = false
				card.states.click.can = false
			end
		end
		if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.update then
			WORD_GAME_UI.TableDeck.update(dt, self)
		end
	end
	if self.config.card_limit > #runtime().letter_inventory then self.config.card_limit = #runtime().letter_inventory end
end

return M
