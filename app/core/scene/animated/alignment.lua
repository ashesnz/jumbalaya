return function(AnimNode)
function AnimNode:set_alignment(args)
	args = args or {}
	if args.major then
		self:set_role({
			role_type = 'Minor',
			major = args.major,
			xy_bond = args.bond or args.xy_bond or 'Weak',
			wh_bond = args.wh_bond or self.role.wh_bond,
			r_bond = args.r_bond or self.role.r_bond,
			scale_bond = args.scale_bond or self.role.scale_bond,
		})
	end
	self.alignment.type = args.type or self.alignment.type
	if args.offset and (type(args.offset) == 'table' and not (args.offset.y and args.offset.x)) or type(args.offset) ~= 'table' then
		args.offset = nil
	end
	self.alignment.offset = args.offset or self.alignment.offset
end

--- Recomputes the role offset so this AnimNode sits at its alignment anchor
--- relative to `role.major`, then snaps `T` onto the major's origin.
function AnimNode:align_to_major()
	if self.alignment.type ~= self.alignment.prev_type then
		self.alignment.type_list = {
			a = self.alignment.type == 'a',
			m = string.find(self.alignment.type, "m"),
			c = string.find(self.alignment.type, "c"),
			b = string.find(self.alignment.type, "b"),
			t = string.find(self.alignment.type, "t"),
			l = string.find(self.alignment.type, "l"),
			r = string.find(self.alignment.type, "r"),
			i = string.find(self.alignment.type, "i"),
		}
	end

	-- Nothing changed since the last pass; skip recomputation. Also skips
	-- only while the major's placement and our measured size are unchanged,
	-- so late room moves (e.g. the screen-wipe card after a button jiggle)
	-- re-align instead of freezing at a stale offset.
	local major, mid, off = self.role.major, self.Mid, self.alignment.offset
	local snap = self.alignment.prev_snap
	if self.alignment.prev_offset.x == off.x
		and self.alignment.prev_offset.y == off.y
		and self.alignment.prev_type == self.alignment.type
		and snap
		and (major == nil or (
			snap.mx == major.T.x and snap.my == major.T.y
			and snap.mw == major.T.w and snap.mh == major.T.h))
		and snap.cw == mid.T.w and snap.ch == mid.T.h then
		return
	end

	self.NEW_ALIGNMENT = true
	if self.alignment.type ~= self.alignment.prev_type then
		self.alignment.prev_type = self.alignment.type
	end

	if self.alignment.type_list.a or not self.role.major then return end

	local tl = self.alignment.type_list

	if tl.m then
		self.role.offset.x = 0.5 * major.T.w - mid.T.w / 2 + off.x - mid.T.x + self.T.x
	end
	if tl.c then
		self.role.offset.y = 0.5 * major.T.h - mid.T.h / 2 + off.y - mid.T.y + self.T.y
	end
	if tl.b then
		self.role.offset.y = tl.i and (off.y + major.T.h - self.T.h) or (off.y + major.T.h)
	end
	if tl.r then
		self.role.offset.x = tl.i and (off.x + major.T.w - self.T.w) or (off.x + major.T.w)
	end
	if tl.t then
		self.role.offset.y = tl.i and off.y or (off.y - self.T.h)
	end
	if tl.l then
		self.role.offset.x = tl.i and off.x or (off.x - self.T.w)
	end

	self.role.offset.x = self.role.offset.x or 0
	self.role.offset.y = self.role.offset.y or 0

	self.T.x = major.T.x + self.role.offset.x
	self.T.y = major.T.y + self.role.offset.y

	self.alignment.prev_offset = self.alignment.prev_offset or {}
	self.alignment.prev_offset.x, self.alignment.prev_offset.y = off.x, off.y
	self.alignment.prev_snap = {
		type = self.alignment.type,
		ox = off.x, oy = off.y,
		mx = major.T.x, my = major.T.y,
		mw = major.T.w, mh = major.T.h,
		cw = mid.T.w, ch = mid.T.h,
	}
end
end
