return function(AnimNode)
--- Horizontal shadow parallax based on room-relative position.
function AnimNode:calculate_parallax()
	if not G.ROOM then return end
	self.shadow_parallax.x = (self.T.x + self.T.w / 2 - G.ROOM.T.w / 2) / (G.ROOM.T.w / 2) * 1.2
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
end

--- Walks up the weld chain returning the top Major plus the accumulated
--- offset (including layered parallax). Cached per frame; invalidated by
--- setting `G.REFRESH_FRAME_MAJOR_CACHE` (e.g. LayoutView recalculation).
function AnimNode:get_major()
	if (self.role.role_type ~= 'Major' and self.role.major ~= self)
		and (self.role.xy_bond ~= 'Weak' and self.role.r_bond ~= 'Weak') then
		if not self.FRAME.MAJOR or G.REFRESH_FRAME_MAJOR_CACHE then
			self.FRAME.MAJOR = clear_table(self.FRAME.MAJOR)
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
