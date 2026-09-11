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

	require "jumbalaya-engine.util.tables"
	require "jumbalaya-engine.util.geometry"
	require "jumbalaya-engine.util.random"
	require "jumbalaya-engine.util.colour"
	require "jumbalaya-engine.graphics.draw"
	require "app.core.platform.display"
	require "jumbalaya-engine.sound.sound"
	require "jumbalaya-engine.util.number_format"

	require "jumbalaya-engine.retained_ui"
	require "jumbalaya-engine.graphics.particles"
	require "jumbalaya-engine.graphics.flow_text"
end

return M
