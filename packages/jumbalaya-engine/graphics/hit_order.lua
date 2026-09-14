
local Tables = require("jumbalaya-engine.util.tables")
local shell = require("jumbalaya-engine.shell")
local game = shell.game

local M = {}

function M.reset_hit_order()
	game().HIT_ORDER = Tables.clear_table(game().HIT_ORDER)
end

--- Records a rendered node in the collision hash (draw order preserved).
function M.track_hit_target(obj)
	if obj then game().HIT_ORDER[#game().HIT_ORDER + 1] = obj end
end

function M.install()
	_G.reset_hit_order = M.reset_hit_order
	_G.track_hit_target = M.track_hit_target
end

return M
