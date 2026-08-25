--[[
	word_game/ui/cardarea/deck.lua - Deck CardArea type behaviour.
]]

local M = {}

local function table_board()
	return G.STATE == G.STATES.TABLE_BOARD
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
			card.T.x = self.T.x + 0.5*(self.T.w - card.T.w) + self.shadow_parallax.x*deck_height*(#self.cards/(self == G.deck and 1 or 2) - k) + 0.9*self.shuffle_amt*(1 - k*0.01)*(k%2 == 1 and 1 or -0)
			card.T.y = self.T.y + 0.5*(self.T.h - card.T.h) + self.shadow_parallax.y*deck_height*(#self.cards/(self == G.deck and 1 or 2) - k)
			card.T.r = 0 + 0.3*self.shuffle_amt*(1 + k*0.05)*(k%2 == 1 and 1 or -0)
			card.T.x = card.T.x + card.shadow_parallax.x/30
		end
	end
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= 'deck' then return end
	if self == G.deck and WORD_GAME and WORD_GAME.TableDeck
		and WORD_GAME.TableDeck.uses_table_draw() then
		if v == 'card' then
			WORD_GAME.TableDeck.draw(self)
		end
	else
		for i = #self.cards, 1, -1 do
			if self.cards[i] ~= G.INPUT.focused.target then
				if i == 1 or i%(self.config.thin_draw or 9) == 0 or i == #self.cards or math.abs(self.cards[i].VT.x - self.T.x) > 1 or math.abs(self.cards[i].VT.y - self.T.y) > 1  then
					draw_card_layer(self.cards[i], v)
				end
			end
		end
	end
end

function M.update(self, dt)
	if self ~= G.deck then return end
	local table_deck = self == G.deck and WORD_GAME and WORD_GAME.TableDeck
		and WORD_GAME.TableDeck.uses_table_draw()
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
		if WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.update then
			WORD_GAME.TableDeck.update(dt, self)
		end
	end
	if self.config.card_limit > #G.playing_cards then self.config.card_limit = #G.playing_cards end
end

return M
