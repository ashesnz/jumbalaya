
local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end
function reset_hit_order()
	g().HIT_ORDER = clear_table(g().HIT_ORDER)
end

--- Records a rendered node in the collision hash (draw order preserved).
function track_hit_target(obj)
	if obj then g().HIT_ORDER[#g().HIT_ORDER + 1] = obj end
end
