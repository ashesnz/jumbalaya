
local Tables = require("jumbalaya-engine.util.tables")
local SceneRoots = require("jumbalaya-engine.scene.roots")
local DropShadow = require("jumbalaya-engine.graphics.drop_shadow")
local shell = require("jumbalaya-engine.shell")
local game = shell.game
return function(AnimNode)
--- Keeps the drop-shadow offset at the engine-wide constant (no room parallax).
function AnimNode:calculate_parallax()
	self.shadow_parallax = self.shadow_parallax or { x = DropShadow.X, y = DropShadow.Y }
	self.shadow_parallax.x = DropShadow.X
	self.shadow_parallax.y = DropShadow.Y
end

--- Merges `args` over the current role. Offsets are accepted only as tables
--- carrying both x and y. Majors never keep a major reference.
---@param args table
function AnimNode:set_role(args)
	if args.major and not args.major.set_role then return end
	if args.offset and (type(args.offset) == 'table' and not (args.offset.y and args.offset.x)) or type(args.offset) ~= 'table' then
		args.offset = nil
	end
	self.role = {
		role_type = args.role_type or self.role.role_type,
		offset = args.offset or self.role.offset,
		major = args.major or self.role.major,
		xy_bond = args.xy_bond or self.role.xy_bond,
		wh_bond = args.wh_bond or self.role.wh_bond,
		r_bond = args.r_bond or self.role.r_bond,
		scale_bond = args.scale_bond or self.role.scale_bond,
		draw_major = args.draw_major or self.role.draw_major,
	}
	if self.role.role_type == 'Major' then self.role.major = nil end
	SceneRoots.sync(self)
end

--- Walks up the weld chain returning the top Major plus the accumulated
--- offset. Cached per frame; invalidated by
--- setting `game().REFRESH_FRAME_MAJOR_CACHE` (e.g. retained panel recalculation).
function AnimNode:get_major()
	if (self.role.role_type ~= 'Major' and self.role.major ~= self)
		and (self.role.xy_bond ~= 'Weak' and self.role.r_bond ~= 'Weak') then
		if not self.FRAME.MAJOR or game().REFRESH_FRAME_MAJOR_CACHE then
			self.FRAME.MAJOR = Tables.clear_table(self.FRAME.MAJOR)
			local parent_major = self.role.major:get_major()
			self.FRAME.MAJOR.major = parent_major.major
			self.FRAME.MAJOR.offset = self.FRAME.MAJOR.offset or {}
			self.FRAME.MAJOR.offset.x = parent_major.offset.x + self.role.offset.x + self.parallax_shift.x
			self.FRAME.MAJOR.offset.y = parent_major.offset.y + self.role.offset.y + self.parallax_shift.y
		end
		return self.FRAME.MAJOR
	end

	self.ARGS.get_major = self.ARGS.get_major or {}
	self.ARGS.get_major.major = self
	self.ARGS.get_major.offset = self.ARGS.get_major.offset or {}
	self.ARGS.get_major.offset.x, self.ARGS.get_major.offset.y = 0, 0
	return self.ARGS.get_major
end
end
