--[[
	jumbalaya-engine/boot.lua - Engine package load order (Love2D shell calls via engine_adapter).
]]

local M = {}

function M.install()
	require "jumbalaya-engine.object"
	require "bit"
	require "jumbalaya-engine.util.pack"
	require "jumbalaya-engine.interaction.router"
	require "jumbalaya-engine.util.tween"
	require "jumbalaya-engine.scene.node"
	require "jumbalaya-engine.scene.animated.init"
	require "jumbalaya-engine.graphics.sprite"
	require "jumbalaya-engine.graphics.sprite_animator"

	require "jumbalaya-engine.globals".install()

	require("jumbalaya-engine.util.tables").install()
	require("jumbalaya-engine.util.geometry").install()
	require("jumbalaya-engine.util.random").install()
	require("jumbalaya-engine.util.colour").install()
	require("jumbalaya-engine.graphics.draw").install()
	require "jumbalaya-engine.adapters.love2d.display"
	require "jumbalaya-engine.sound.sound"
	require("jumbalaya-engine.util.number_format").install()

	require "jumbalaya-engine.panels"
	require "jumbalaya-engine.graphics.particles"
	require "jumbalaya-engine.graphics.flow_text"
end

return M
