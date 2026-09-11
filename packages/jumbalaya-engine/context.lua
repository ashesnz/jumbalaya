--[[
	jumbalaya-engine/context.lua - Service context (store + engine services).
]]

local Renderer = require("jumbalaya-engine.renderer")
local InputService = require("jumbalaya-engine.input")
local AudioService = require("jumbalaya-engine.audio")
local Clock = require("jumbalaya-engine.clock")
local Love2D = require("jumbalaya-engine.adapters.love2d")

---@class EngineContext
local Context = {}
Context.__index = Context

function Context.new(opts)
	opts = opts or {}
	local store = opts.store
	local ctx = setmetatable({
		store = store,
		renderer = opts.renderer or Renderer.new(Love2D.renderer()),
		input = opts.input or InputService.new(store),
		audio = opts.audio or AudioService.new(),
		clock = opts.clock or Clock.from_globals(),
	}, Context)

	if store and ctx.audio and ctx.audio.bind_store then
		ctx.audio:bind_store(store)
	end
	return ctx
end

return Context
