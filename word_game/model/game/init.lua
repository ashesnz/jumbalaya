--[[
	word_game/model/game/init.lua - Game class and stage prep.
]]

local Kind = require("app.core.object")

Game = Kind:derive("Game")

function Game:construct()
	---@diagnostic disable-next-line: global-in-non-module
	G = self
	self:define_constants()
end

function Game:prep_stage(new_stage, new_state, new_game_obj)
	for k in pairs(self.INPUT.locks) do self.INPUT.locks[k] = nil end
	if new_game_obj then self.GAME = self:init_game_object() end
	self.STAGE = new_stage or self.STAGES.MAIN_MENU
	self.STATE = new_state or self.STATES.MENU
	self.STATE_COMPLETE = false
	self.SETTINGS.paused = false
	self.ROOM = SceneNode{T={x = self.ROOM_PADDING_W, y = self.ROOM_PADDING_H, w = self.TILE_W, h = self.TILE_H}}
	self.ROOM.jiggle = 0
	self.ROOM.states.drag.can = false
	self.ROOM:set_container(self.ROOM)
	self.ROOM_ATTACH = EaseNode{T={x = 0, y = 0, w = self.TILE_W, h = self.TILE_H}}
	self.ROOM_ATTACH.states.drag.can = false
	self.ROOM_ATTACH:set_container(self.ROOM)
	local sidebar_w = (WORD_GAME and WORD_GAME.Layout and WORD_GAME.Layout.sidebar_width())
		or self.TABLE_BOARD_SIDEBAR_WIDTH
		or (self.TABLE_BOARD_SIDEBAR_FRAC and self.TILE_W * self.TABLE_BOARD_SIDEBAR_FRAC) or 3.0
	self.PANEL_ATTACH = EaseNode{T={x = self.TILE_W - sidebar_w, y = 0, w = sidebar_w, h = self.TILE_H}}
	self.PANEL_ATTACH.states.drag.can = false
	self.PANEL_ATTACH:set_container(self.ROOM)
	self.VAULT_ATTACH = EaseNode{T={x = self.TILE_W - sidebar_w, y = 0, w = sidebar_w, h = self.TILE_H}}
	self.VAULT_ATTACH.states.drag.can = false
	self.VAULT_ATTACH:set_container(self.ROOM)
	self.PLAY_ATTACH = EaseNode{T={x = 0, y = 2.0, w = self.TILE_W - sidebar_w, h = self.TILE_H - 3.5}}
	self.PLAY_ATTACH.states.drag.can = false
	self.PLAY_ATTACH:set_container(self.ROOM)
	if love.graphics and love.graphics.getWidth and love.graphics.getHeight then require("app.core.platform.window").sync_resize() end
end

require "word_game.model.game.run"
require "word_game.model.game.loop"

return Game
