--[[
	jumbalaya-engine/scene/input_flags.lua - hover/click/drag capability + live bits.

	Nested `can` / `is` tables are the backing store. Engine interaction and
	new call sites use flat aliases (`hoverable`, `dragging`, …).
]]

local function pair(can, is)
	return { can = can and true or false, is = is and true or false }
end

local FLAT = {
	hoverable = { "hover", "can" },
	hovering = { "hover", "is" },
	clickable = { "click", "can" },
	clicking = { "click", "is" },
	draggable = { "drag", "can" },
	dragging = { "drag", "is" },
	collideable = { "collide", "can" },
	colliding = { "collide", "is" },
	focusable = { "focus", "can" },
	focused = { "focus", "is" },
	releasable = { "release_on", "can" },
	released = { "release_on", "is" },
}

local mt = {
	__index = function(t, key)
		local path = FLAT[key]
		if path then return t[path[1]][path[2]] end
		return nil
	end,
	__newindex = function(t, key, value)
		local path = FLAT[key]
		if path then
			t[path[1]][path[2]] = value and true or false
			return
		end
		rawset(t, key, value)
	end,
}

local M = {}

function M.new()
	return setmetatable({
		visible = true,
		collide = pair(false, false),
		focus = pair(false, false),
		hover = pair(true, false),
		click = pair(true, false),
		drag = pair(true, false),
		release_on = pair(true, false),
	}, mt)
end

return M
