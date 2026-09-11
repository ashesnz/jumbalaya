--[[ jumbalaya-engine/services/context.lua - Bundles store + engine services ]]

local Renderer = require("jumbalaya-engine.services.renderer")
local InputService = require("jumbalaya-engine.services.input")
local AudioService = require("jumbalaya-engine.services.audio")
local Clock = require("jumbalaya-engine.services.clock")
local EventBus = require("jumbalaya-engine.services.event_bus")
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
		events = opts.events or EventBus.new(),
	}, Context)

	if store and ctx.audio and ctx.audio.bind_store then
		ctx.audio:bind_store(store)
	end
	return ctx
end

return Context
