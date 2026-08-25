--[[
	word_game.board/placement_table.lua - Session controller for the placement row.

	Owns the placement CardArea. Subsystems (layout, draw, snap) are stateless
	modules that receive `self` as their session.

	Lifecycle (called from Game):
	  PlacementTable(game)  -> construct with Game reference
	  :create_area(w, h)    -> instantiate CardArea during start_run
	  :setup()              -> reset row state at run start
	  :draw_shadows()       -> called from CardArea:draw
	  :relayout()        -> called from CardArea:relayout
	  :try_snap_card(card)  -> called from Card:stop_drag
	  :draw_run_pass(game)  -> board draw pass (area + placed cards)
]]

local PlacementContext = require "word_game.board.context"
local Kind = require "app.core.object"
local layout = require "word_game.board.layout"
local draw = require "word_game.board.draw"
local snap = require "word_game.board.snap"
local shimmer = require "word_game.board.shimmer"
local jumble_geometry = require "word_game.board.jumble_geometry"
local jumble_fixed_letters = require "word_game.ui.jumble_fixed_letters"

--- @class PlacementTable
--- @field game Game
--- @field ctx PlacementContext
--- @field area CardArea|nil
local PlacementTable = Kind:derive("PlacementTable")

--- @param game Game
function PlacementTable:construct(game)
	self.game = game
	self.ctx = PlacementContext.new(game)
	self.area = nil
	self.card_shimmer_t = {}
	self.jumble_geometry = jumble_geometry
end

--- Create the CardArea if it does not exist yet (during start_run).
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

	self.area = CardArea(
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
			and not (WORD_GAME and WORD_GAME.CardInspect and WORD_GAME.CardInspect.is(v)) then
			love.graphics.push()
			v:translate_container()
			v:draw()
			love.graphics.pop()
		end
	end

	love.graphics.push()
	self.area:translate_container()
	shimmer.draw(self)
	if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active() then
		jumble_fixed_letters.draw(self)
	end
	love.graphics.pop()
end

--- Draw a card being dragged from/to the placement row.
--- @param card Card
function PlacementTable:draw_dragged_card(card)
	if not card or not self.area then return end
	love.graphics.push()
	card:translate_container()
	card:draw()
	love.graphics.pop()
end

return PlacementTable
