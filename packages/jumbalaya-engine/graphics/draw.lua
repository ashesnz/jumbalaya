--[[ jumbalaya-engine/graphics/draw.lua - aggregates the low-level draw helpers ]]

local M = {}

function M.install()
	require("jumbalaya-engine.graphics.hit_order").install()
	require("jumbalaya-engine.graphics.node_transform").install()
	require("jumbalaya-engine.graphics.polygons").install()
end

return M
