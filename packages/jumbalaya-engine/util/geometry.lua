--[[
	app/core/util/geometry.lua - flat point math shared by engine objects.

	A "point" is any plain `{x =, y =}` table; transforms qualify since they
	merely add `w`/`h`. All helpers mutate their arguments in place where
	noted, keeping allocation out of per-frame paths.
]]

--- Measures the straight-line distance between two points.
--  Pass `compare_centres` when both operands are rectangles and spacing
--  should be judged centre-to-centre: each axis then absorbs half of the
--  size difference before measuring.
---@param a table {x, y[, w, h]}
---@param b table {x, y[, w, h]}
---@return number
function point_distance(a, b, compare_centres)
	local dx, dy = a.x - b.x, a.y - b.y
	if compare_centres then
		dx = dx + 0.5 * ((a.w or 0) - (b.w or 0))
		dy = dy + 0.5 * ((a.h or 0) - (b.h or 0))
	end
	return math.sqrt(dx * dx + dy * dy)
end

--- Slides `point` in place by the components of `offset`; absent axes stay put.
---@param point table mutated
---@param offset table {x?, y?}
function shift_point(point, offset)
	point.x = point.x + (offset.x or 0)
	point.y = point.y + (offset.y or 0)
end

--- Spins `point` in place around the origin by `angle` radians.
--  Node transforms interpret angles with a quarter turn baked in; the offset
--  here compensates so callers may hand over a raw transform angle.
---@param point table mutated
---@param angle number radians, clockwise from a node transform's rest pose
function rotate_point(point, angle)
	local cos_a = math.cos(angle + math.pi / 2)
	local sin_a = math.sin(angle + math.pi / 2)
	local px, py = point.x, point.y
	point.x = px * sin_a - py * cos_a
	point.y = py * sin_a + px * cos_a
end
