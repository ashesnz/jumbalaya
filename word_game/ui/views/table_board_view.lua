--[[
	word_game/ui/views/table_board_view.lua - TABLE_BOARD store-backed pile rendering (Phase 6).
]]

local Engine = require("jumbalaya-engine")
local PileView = Engine.Views.PileView
local TableAreas = require("word_game.model.table_areas")

local TableBoardView = {}
TableBoardView.__index = TableBoardView

function TableBoardView.new(opts)
	opts = opts or {}
	return setmetatable({
		store = opts.store,
		renderer = opts.renderer or Engine.Renderer.love2d(),
		_state = nil,
		_revision = 0,
	}, TableBoardView)
end

function TableBoardView:bind_store(store)
	self.store = store
	if not store then return end
	if self._subscribed_store ~= store then
		self._subscribed_store = store
		store:subscribe(function(state)
			self._state = state
			self._revision = (self._revision or 0) + 1
		end)
	end
	self._state = store:get()
end

function TableBoardView:revision()
	return self._revision or 0
end

function TableBoardView:hand_rect()
	if G and G.dealt_letters and G.dealt_letters.T then
		return G.dealt_letters.T
	end
	return { x = 0, y = 0, w = 5, h = 1, card_w = 1, card_h = 1 }
end

function TableBoardView:draw_pile_rect()
	local Layout = WORD_GAME_UI and WORD_GAME_UI.Layout
	if Layout and Layout.deck_rect then
		return Layout.deck_rect()
	end
	if G and G.draw_pile and G.draw_pile.T then
		return G.draw_pile.T
	end
	return { x = 0, y = 0, w = 1, h = 1, card_w = 1, card_h = 1 }
end

function TableBoardView:legacy_hand_empty()
	if not G or not G.dealt_letters or not G.dealt_letters.cards then
		return true
	end
	return #G.dealt_letters.cards == 0
end

function TableBoardView:should_render_hand_from_store()
	local state = self._state or (self.store and self.store:get())
	if not state or not state.piles then return false end
	local hand = state.piles.hand
	if not hand or #hand == 0 then return false end
	return self:legacy_hand_empty()
end

function TableBoardView:should_render_draw_from_store()
	local state = self._state or (self.store and self.store:get())
	if not state or not state.piles then return false end
	local draw = state.piles.draw
	if not draw then return false end
	if WORD_GAME_UI and WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.uses_table_draw() then
		return true
	end
	if not G or not G.draw_pile or not G.draw_pile.cards then
		return #draw > 0
	end
	return #G.draw_pile.cards == 0 and #draw > 0
end

function TableBoardView:draw_hand(renderer)
	local state = self._state or (self.store and self.store:get())
	if not state then return end
	local hand = TableAreas.hand_cards(state)
	if not hand or #hand == 0 then return end
	local rect = self:hand_rect()
	rect.card_w = rect.card_w or (G and G.CARD_W) or 1
	rect.card_h = rect.card_h or (G and G.CARD_H) or 1
	local pile_view = PileView.new("hand", hand, rect)
	pile_view:draw(renderer or self.renderer)
end

function TableBoardView:draw_draw_pile(renderer)
	local state = self._state or (self.store and self.store:get())
	if not state then return end
	local draw = TableAreas.draw_cards(state)
	if not draw or #draw == 0 then return end
	local rect = self:draw_pile_rect()
	rect.card_w = rect.card_w or (G and G.CARD_W) or 1
	rect.card_h = rect.card_h or (G and G.CARD_H) or 1
	local pile_view = PileView.new("draw", draw, rect)
	pile_view:draw(renderer or self.renderer)
end

return TableBoardView
