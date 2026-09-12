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
	require "jumbalaya-engine.adapters.love2d.display"
	require "jumbalaya-engine.sound.sound"
	local NumberFormat = require "jumbalaya-engine.util.number_format"
	number_format = NumberFormat.number_format
	score_number_scale = NumberFormat.score_number_scale

	require "jumbalaya-engine.panels"
	require "jumbalaya-engine.graphics.particles"
	require "jumbalaya-engine.graphics.flow_text"
end

return M
