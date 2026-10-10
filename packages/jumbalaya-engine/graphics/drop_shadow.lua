--[[ jumbalaya-engine/graphics/drop_shadow.lua - Single drop-shadow offset + alpha ]]

local M = {
	X = 0.10,
	Y = 0.14,
	ALPHA = 0.30,
}

function M.pixels(tile_size)
	tile_size = tile_size or 1
	return M.X * tile_size, M.Y * tile_size
end

function M.rgba(alpha_scale)
	return 0, 0, 0, M.ALPHA * (alpha_scale or 1)
end

return M
