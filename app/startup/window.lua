--[[
	app/startup/window.lua - Viewport and window initialization.
]]

local Funcs = require("bridge.funcs_registry")

function Game:init_window(reset)
	self.ROOM_PADDING_H= 0.7
	self.ROOM_PADDING_W = 1
	self.WINDOW_TRANSFORM = {
		x = 0, y = 0,
		w = self.TILE_W+2*self.ROOM_PADDING_W,
		h = self.TILE_H+2*self.ROOM_PADDING_H
	}
	self.window_prev = {
		orig_scale = self.TILESCALE,
		w=self.WINDOW_TRANSFORM.w*self.TILESIZE*self.TILESCALE,
		h=self.WINDOW_TRANSFORM.h*self.TILESIZE*self.TILESCALE,
		orig_ratio = self.WINDOW_TRANSFORM.w*self.TILESIZE*self.TILESCALE/(self.WINDOW_TRANSFORM.h*self.TILESIZE*self.TILESCALE)}
	self.SETTINGS.QUEUED_CHANGE = self.SETTINGS.QUEUED_CHANGE or {}
	self.SETTINGS.QUEUED_CHANGE.screenmode = self.SETTINGS.WINDOW.screenmode

	local os_name = love.system.getOS()
	if os_name == 'iOS' or os_name == 'Android' then
		local Window = require "app.core.platform.window"
		Window.sync_resize()
		self.SETTINGS.QUEUED_CHANGE = {}
		return
	end

	Funcs.dispatch("apply_window_changes", true)
	local Window = require "app.core.platform.window"
	Window.sync_resize()
end
