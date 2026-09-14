--[[
	jumbalaya-engine/boot.lua - Engine package load order (Love2D shell calls via engine_adapter).
]]

local M = {}

function M.install()
	require "jumbalaya-engine.object"
	require "bit"
	require "jumbalaya-engine.util.pack"
	require("jumbalaya-engine.util.tables").install()
	require("jumbalaya-engine.util.geometry").install()
	require("jumbalaya-engine.util.random").install()
	require("jumbalaya-engine.util.colour").install()
	require("jumbalaya-engine.graphics.draw").install()
	require("jumbalaya-engine.util.number_format").install()

	require "jumbalaya-engine.globals".install()
	require "jumbalaya-engine.panels.container"

	require "jumbalaya-engine.adapters.love2d.display"
	require "jumbalaya-engine.sound.sound"
end

return M
