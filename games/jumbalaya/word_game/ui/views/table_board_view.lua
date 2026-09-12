--[[
	word_game/ui/views/table_board_view.lua - TABLE_BOARD store-backed pile rendering (Phase 6 / 10b).
]]

local facade = require("word_game.ui.facade")
local piles = facade.piles()
local TableAreas = facade.table_areas()
local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Engine = require("jumbalaya-engine")
local PileView = Engine.Views.PileView

local TableBoardView = {}
TableBoardView.__index = TableBoardView

local PILE_HOSTS = {
	hand = "dealt_letters",
	draw = "draw_pile",
	pattern = "pattern_row",
}

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

function TableBoardView:state()
	return self._state or (self.store and self.store:get())
end

function TableBoardView:legacy_host(pile_id)
	local key = PILE_HOSTS[pile_id]
	if not key or not runtime() then return nil end
	if pile_id == "pattern" then
		local row = runtime().pattern_row
		return row and row.area
	end
	return runtime()[key]
end

function TableBoardView:interaction_cards()
	local out = {}
	local controller = runtime() and runtime().INPUT
	if not controller then return out end
	if controller.dragging and controller.dragging.target then
		out[controller.dragging.target] = true
	end
	if controller.focused and controller.focused.target then
		out[controller.focused.target] = true
	end
	return out
end

local PILE_SELECTORS = {
	hand = TableAreas.hand_cards,
	draw = TableAreas.draw_cards,
	pattern = TableAreas.pattern_cards,
	discard = TableAreas.recycle_cards,
	bonus = TableAreas.bonus_cards,
}

function TableBoardView:pile_cards(pile_id, state)
	state = state or self:state()
	if not state then return {} end
	local selector = PILE_SELECTORS[pile_id]
	if selector then
		return selector(state)
	end
	return state.piles and state.piles[pile_id] or {}
end

function TableBoardView:should_render_pile_from_store(pile_id)
	local state = self:state()
	if not state or not state.piles then return false end
	local pile = state.piles[pile_id]
	if not pile or #pile == 0 then return false end
	if pile_id == "draw" and WORD_GAME_UI and WORD_GAME_UI.TableDeck
		and WORD_GAME_UI.TableDeck.uses_table_draw() then
		return true
	end
	return true
end

function TableBoardView:should_render_hand_from_store()
	return self:should_render_pile_from_store("hand")
end

function TableBoardView:should_render_draw_from_store()
	return self:should_render_pile_from_store("draw")
end

function TableBoardView:should_render_pattern_from_store()
	return self:should_render_pile_from_store("pattern")
end

function TableBoardView:hand_rect()
	if runtime() and runtime().dealt_letters and runtime().dealt_letters.T then
		return runtime().dealt_letters.T
	end
	return { x = 0, y = 0, w = 5, h = 1, card_w = 1, card_h = 1 }
end

function TableBoardView:draw_pile_rect()
	local Layout = WORD_GAME_UI and WORD_GAME_UI.Layout
	if Layout and Layout.deck_rect then
		return Layout.deck_rect()
	end
	if runtime() and runtime().draw_pile and runtime().draw_pile.T then
		return runtime().draw_pile.T
	end
	return { x = 0, y = 0, w = 1, h = 1, card_w = 1, card_h = 1 }
end

function TableBoardView:pattern_rect()
	if runtime() and runtime().pattern_row and runtime().pattern_row.area and runtime().pattern_row.area.T then
		return runtime().pattern_row.area.T
	end
	return { x = 0, y = 0, w = 8, h = 1, card_w = 1, card_h = 1 }
end

function TableBoardView:decorate_rect(rect)
	rect.card_w = rect.card_w or (runtime() and runtime().CARD_W) or 1
	rect.card_h = rect.card_h or (runtime() and runtime().CARD_H) or 1
	return rect
end

function TableBoardView:draw_pile(pile_id, rect, renderer)
	local cards = self:pile_cards(pile_id)
	if not cards or #cards == 0 then return end
	rect = self:decorate_rect(rect or {})
	local pile_view = PileView.new(pile_id, cards, rect)
	pile_view:draw(renderer or self.renderer)
end

function TableBoardView:draw_hand(renderer)
	self:draw_pile("hand", self:hand_rect(), renderer)
end

function TableBoardView:draw_draw_pile(renderer)
	self:draw_pile("draw", self:draw_pile_rect(), renderer)
end

function TableBoardView:draw_pattern(renderer)
	self:draw_pile("pattern", self:pattern_rect(), renderer)
end

function TableBoardView:draw_static_piles(renderer)
	if self:should_render_hand_from_store() then
		self:draw_hand(renderer)
	end
	if self:should_render_draw_from_store() then
		self:draw_draw_pile(renderer)
	end
	if self:should_render_pattern_from_store() then
		self:draw_pattern(renderer)
	end
end

return TableBoardView
