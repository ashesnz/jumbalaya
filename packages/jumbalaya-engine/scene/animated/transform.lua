return function(Spatial)
local Geometry = require("jumbalaya-engine.util.geometry")
local shell = require("jumbalaya-engine.shell")
local game = shell.game

local Node = require("jumbalaya-engine.scene.node")

local drag_cursor = {}
local drag_trans = {}

--- Teleports both target and drawn to (X, Y, W, H) and kills velocity.
function Spatial:snap_rect(X, Y, W, H)
	local T = self.target or self.T
	local VT = self.drawn or self.VT
	T.x, T.y, T.w, T.h = X, Y, W, H
	self.velocity.x, self.velocity.y, self.velocity.r, self.velocity.scale = 0, 0, 0, 0
	VT.x, VT.y, VT.w, VT.h = X, Y, W, H
	VT.r = T.r
	VT.scale = T.scale
	self:calculate_parallax()
end

--- Snaps only the drawn rect onto the layout target (no velocity reset).
function Spatial:snap_drawn()
	local T = self.target or self.T
	local VT = self.drawn or self.VT
	VT.x = T.x
	VT.y = T.y
	VT.w = T.w
	VT.h = T.h
end

--- Follows the cursor: converts cursor pixels into room space, then pins
--- target to the grab point recorded by `set_offset(.., 'Click')`.
function Spatial:drag(offset)
	if self.states.draggable or offset then
		local p, t = drag_cursor, drag_trans
		local root = self:coord_root()
		local root_T = root.target or root.T
		p.x = game().INPUT.cursor_position.x / (game().TILESCALE * game().TILESIZE)
		p.y = game().INPUT.cursor_position.y / (game().TILESCALE * game().TILESIZE)

		t.x, t.y = -root_T.w / 2, -root_T.h / 2
		Geometry.shift_point(p, t)
		Geometry.rotate_point(p, root_T.r or 0)
		t.x, t.y = root_T.w / 2 - root_T.x, root_T.h / 2 - root_T.y
		Geometry.shift_point(p, t)

		offset = offset or self.click_offset

		local T = self.target or self.T
		T.x = p.x - offset.x
		T.y = p.y - offset.y
		if self.attach then self.attach.dirty = true end
		for _, v in pairs(self.children) do v:drag(offset) end
	end
	if self.states.draggable then Node.drag(self) end
end
end
