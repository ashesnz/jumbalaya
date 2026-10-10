
local shell = require("jumbalaya-engine.shell")
local game = shell.game

local M = {}

function M.push_node_transform(node, scale, rotate, offset, _)
	love.graphics.push()
	love.graphics.scale(game().TILESCALE * game().TILESIZE)
	local drawn = node.drawn or node.VT
	local parallax = node.parallax_shift
		or (node.parent and node.parent.parallax_shift)
		or {x = 0, y = 0}
	love.graphics.translate(
		drawn.x + drawn.w / 2 + (offset and offset.x or 0) + parallax.x,
		drawn.y + drawn.h / 2 + (offset and offset.y or 0) + parallax.y)
	if drawn.r ~= 0 or node.bounce or rotate then
		love.graphics.rotate(drawn.r + (rotate or 0))
	end
	love.graphics.translate(
		-scale * drawn.w * drawn.scale / 2,
		-scale * drawn.h * drawn.scale / 2)
	love.graphics.scale(drawn.scale * scale)
end

function M.install()
end

return M
