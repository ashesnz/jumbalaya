--[[
	word_game.board.placement.table - Session controller for the placement row.

	Owns the placement CardPile. Subsystems (layout, draw, snap) are stateless
	modules that receive `self` as their session.

	Lifecycle (called from Game):
	  PlacementTable(game)  -> construct with Game reference
	  :create_area(w, h)    -> instantiate CardPile during start_run
	  :setup()              -> reset row state at run start
	  :draw_shadows()       -> called from CardPile:draw
	  :relayout()           -> called from CardPile:relayout
	  :try_snap_card(card)  -> called from Card:stop_drag
	  :draw_run_pass(game)  -> board draw pass (area + placed cards)
]]

local PlacementContext = require "word_game.board.placement.context"
local Kind = require "app.core.object"
local game_access = require("word_game.model.game_access")
local layout = require "word_game.board.placement.layout"
local draw = require "word_game.board.placement.draw"
local snap = require "word_game.board.placement.snap"
local shimmer = require "word_game.board.placement.shimmer"
local jumble_geometry = require "word_game.board.jumble.geometry"

local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end

--- @class PlacementTable
--- @field game Game
--- @field ctx PlacementContext
--- @field area CardPile|nil
--- @field draw_pattern_overlay fun(session)|nil UI hook for fixed-letter tiles
local PlacementTable = Kind:derive("PlacementTable")

--- @param game Game
function PlacementTable:construct(game)
	self.game = game
	self.ctx = PlacementContext.new(game)
	self.area = nil
	self.card_shimmer_t = {}
	self.jumble_geometry = jumble_geometry
end

--- Create the CardPile if it does not exist yet (during start_run).
--- @param w number area width in room units
--- @param h number area height in room units
function PlacementTable:create_area(w, h)
	if self.area and not self.area.cards then
		self.area = nil
	end
	if self.area then
		self.area.T.w = w
		self.area.T.h = h
		return self.area
	end

	self.area = CardPile(
		0, 0, w, h,
		{
			card_limit = self.ctx:card_limit(),
			type = 'placement',
			selection_limit = 1,
		}
	)
	return self.area
end

function PlacementTable:setup()
	self.card_shimmer_t = {}
	if self.area then
		self.area.config.card_limit = self.ctx:card_limit()
	end
end

function PlacementTable:update(dt)
	shimmer.update(self, dt)
end

function PlacementTable:area_width()
	return layout.area_width(self.ctx)
end

function PlacementTable:area_height()
	return layout.area_height(self.ctx)
end

function PlacementTable:apply_screen_position()
	if not self.area or not self.area.cards then
		self:create_area(self:area_width(), self:area_height())
	end
	layout.apply_screen_position(self)
end

function PlacementTable:draw_shadows()
	draw.shadows(self)
end

function PlacementTable:relayout()
	layout.relayout(self)
end

function PlacementTable:on_remove_card(card)
	snap.clear_card(self, card)
end

function PlacementTable:try_snap_card(card)
	snap.try_snap(self, card)
end

--- Draw placement area and placed cards during board mode.
--- @param game Game
function PlacementTable:draw_run_pass(game)
	if not self.area or not self.area.cards then return end

	local j = WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state and WORD_GAME.Jumble.state()
	if j and j.boss_puzzle_hidden then return end

	love.graphics.push()
	self.area:translate_container()
	self.area:draw()
	love.graphics.pop()

	local controller = game.INPUT
	for _, v in pairs(game.LIVE.CARD) do
		if v.area == self.area
			and (not v.parent and v ~= controller.dragging.target and v ~= controller.focused.target)
			and not (game_access.get() and game_access.get().inspecting_card == v) then
			love.graphics.push()
			v:translate_container()
			v:draw()
			love.graphics.pop()
		end
	end

	love.graphics.push()
	self.area:translate_container()
	shimmer.draw(self)
	if self.draw_pattern_overlay then
		self.draw_pattern_overlay(self)
	end
	love.graphics.pop()
end

return PlacementTable
