--[[
	jumbalaya-engine - Engine service interfaces and Love2D adapters (Phase 3).
]]

local Renderer = require("jumbalaya-engine.renderer")
local InputService = require("jumbalaya-engine.input")
local AudioService = require("jumbalaya-engine.audio")
local Clock = require("jumbalaya-engine.clock")

return {
	Renderer = Renderer,
	InputService = InputService,
	AudioService = AudioService,
	Clock = Clock,
}
