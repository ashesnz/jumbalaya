
local Geometry = require("jumbalaya-engine.util.geometry")
local shell = require("jumbalaya-engine.shell")
local game = shell.game

local scratch_point = {}
local scratch_trans = {}
local scratch_rot = {}
local offset_point = {}
local offset_trans = {}

return function(Node)
	function Node:collides_with_point(point)
		local root = (self.coord_root and self:coord_root()) or self.container
		if not root then return end

		local T = self.CT or self.drawn or self.VT or self.T
		local p, t, rot = scratch_point, scratch_trans, scratch_rot
		local root_T = root.target or root.T

		local buffer = self.states.hovering and game().COLLISION_BUFFER or 0
		p.x, p.y = point.x, point.y

		if root ~= self then
			local root_r = root_T.r or 0
			if math.abs(root_r) < 0.1 then
				t.x, t.y = -root_T.w / 2, -root_T.h / 2
				Geometry.shift_point(p, t)
				Geometry.rotate_point(p, root_r)
				t.x, t.y = root_T.w / 2 - root_T.x, root_T.h / 2 - root_T.y
				Geometry.shift_point(p, t)
			else
				t.x, t.y = -root_T.x, -root_T.y
				Geometry.shift_point(p, t)
			end
		end

		if math.abs(T.r) < 0.1 then
			return p.x >= T.x - buffer and p.y >= T.y - buffer
				and p.x <= T.x + T.w + buffer and p.y <= T.y + T.h + buffer
		end

		rot.cos, rot.sin = math.cos(T.r + math.pi / 2), math.sin(T.r + math.pi / 2)
		p.x, p.y = p.x - (T.x + 0.5 * T.w), p.y - (T.y + 0.5 * T.h)
		t.x, t.y = p.y * rot.cos - p.x * rot.sin, p.y * rot.sin + p.x * rot.cos
		p.x, p.y = t.x + (T.x + 0.5 * T.w), t.y + (T.y + 0.5 * T.h)

		return p.x >= T.x - buffer and p.y >= T.y - buffer
			and p.x <= T.x + T.w + buffer and p.y <= T.y + T.h + buffer
	end

	function Node:set_offset(point, kind)
		local p, t = offset_point, offset_trans

		local root = (self.coord_root and self:coord_root()) or self.container
		local root_T = root.target or root.T
		p.x, p.y = point.x, point.y
		t.x, t.y = -root_T.w / 2, -root_T.h / 2
		Geometry.shift_point(p, t)
		Geometry.rotate_point(p, root_T.r or 0)
		t.x, t.y = root_T.w / 2 - root_T.x, root_T.h / 2 - root_T.y
		Geometry.shift_point(p, t)

		local T = self.target or self.T
		if kind == "Click" then
			self.click_offset.x = p.x - T.x
			self.click_offset.y = p.y - T.y
		elseif kind == "Hover" then
			self.hover_offset.x = p.x - T.x
			self.hover_offset.y = p.y - T.y
		end
	end

	function Node:put_focused_cursor()
		local units = game().TILESCALE * game().TILESIZE
		local T = self.target or self.T
		local root = (self.coord_root and self:coord_root()) or self.container
		local root_T = root.target or root.T
		return (T.x + T.w / 2 + root_T.x) * units,
			(T.y + T.h / 2 + root_T.y) * units
	end

	function Node:fast_mid_dist(other_node)
		return math.sqrt((other_node.T.x + 0.5 * other_node.T.w) - (self.T.x + self.T.w)) ^ 2
			+ ((other_node.T.y + 0.5 * other_node.T.h) - (self.T.y + self.T.h)) ^ 2
	end
end
