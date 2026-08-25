return function(AnimNode)
local Node = require("app.core.scene.node")
--- Teleports both transforms to (X, Y, W, H) and kills all velocity.
function AnimNode:hard_set_T(X, Y, W, H)
	self.T.x, self.T.y, self.T.w, self.T.h = X, Y, W, H
	self.velocity.x, self.velocity.y, self.velocity.r, self.velocity.scale = 0, 0, 0, 0
	self.VT.x, self.VT.y, self.VT.w, self.VT.h = X, Y, W, H
	self.VT.r = self.T.r
	self.VT.scale = self.T.scale
	self:calculate_parallax()
end

--- Snaps only the visible transform onto the logical one (no velocity reset).
function AnimNode:snap_VT()
	self.VT.x = self.T.x
	self.VT.y = self.T.y
	self.VT.w = self.T.w
	self.VT.h = self.T.h
end

--- Follows the cursor: converts cursor pixels into container space, then pins
--- `T` to the grab point recorded by `set_offset(.., 'Click')`.
function AnimNode:drag(offset)
	if self.states.drag.can or offset then
		self.ARGS.drag_cursor_trans = self.ARGS.drag_cursor_trans or {}
		self.ARGS.drag_translation = self.ARGS.drag_translation or {}
		local p = self.ARGS.drag_cursor_trans
		local t = self.ARGS.drag_translation
		p.x = G.INPUT.cursor_position.x / (G.TILESCALE * G.TILESIZE)
		p.y = G.INPUT.cursor_position.y / (G.TILESCALE * G.TILESIZE)

		t.x, t.y = -self.container.T.w / 2, -self.container.T.h / 2
		shift_point(p, t)
		rotate_point(p, self.container.T.r)
		t.x, t.y = self.container.T.w / 2 - self.container.T.x, self.container.T.h / 2 - self.container.T.y
		shift_point(p, t)

		offset = offset or self.click_offset

		self.T.x = p.x - offset.x
		self.T.y = p.y - offset.y
		self.NEW_ALIGNMENT = true
		for _, v in pairs(self.children) do v:drag(offset) end
	end
	if self.states.drag.can then Node.drag(self) end
end
end
