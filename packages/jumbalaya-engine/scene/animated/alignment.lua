local function parse_anchor(args, previous)
	if args and args.anchor then
		local a = args.anchor
		return {
			x = a.x or "none",
			y = a.y or "none",
			inset = not not a.inset,
			absolute = not not a.absolute,
		}
	end
	local type_str = (args and args.type) or (previous and previous.type) or "a"
	if type(type_str) == "table" then
		return {
			x = type_str.x or "none",
			y = type_str.y or "none",
			inset = not not type_str.inset,
			absolute = not not type_str.absolute,
		}
	end
	type_str = type_str or "a"
	return {
		x = type_str:find("m", 1, true) and "center"
			or type_str:find("r", 1, true) and "right"
			or type_str:find("l", 1, true) and "left"
			or "none",
		y = type_str:find("c", 1, true) and "center"
			or type_str:find("b", 1, true) and "bottom"
			or type_str:find("t", 1, true) and "top"
			or "none",
		inset = not not type_str:find("i", 1, true),
		absolute = type_str == "a" or type_str == "",
	}
end

local function anchor_key(anchor)
	return (anchor.x or "none") .. "/" .. (anchor.y or "none")
		.. (anchor.inset and "/i" or "") .. (anchor.absolute and "/a" or "")
end

return function(Spatial)
	function Spatial:set_alignment(args)
		args = args or {}
		if args.major then
			local lock
			if args.bond ~= nil then
				lock = args.bond == "Strong"
			elseif self.attach and self.attach.lock_drawn ~= nil then
				lock = self.attach.lock_drawn and true or false
			else
				lock = true
			end
			-- Alignment offset is applied in apply_alignment, not as the follow
			-- weld offset (that would fight center-center every tick).
			self:follow(args.major, nil, { lock_drawn = lock })
		end
		self.alignment.type = args.type or self.alignment.type
		self.alignment.anchor = parse_anchor(args, self.alignment)
		if args.offset and (type(args.offset) == "table" and not (args.offset.y and args.offset.x)) or type(args.offset) ~= "table" then
			args.offset = nil
		end
		self.alignment.offset = args.offset or self.alignment.offset
	end

	--- Recomputes follow offset from a named anchor on `attach.host`.
	function Spatial:apply_alignment()
		local anchor = self.alignment.anchor or parse_anchor(nil, self.alignment)
		self.alignment.anchor = anchor
		local key = anchor_key(anchor)

		local attach = self.attach or {}
		local major, mid, off = attach.host, self.Mid, self.alignment.offset
		local T = self.target or self.T
		local major_T = major and (major.target or major.T)
		local mid_T = mid and (mid.target or mid.T)
		local snap = self.alignment.prev_snap
		if self.alignment.prev_offset.x == off.x
			and self.alignment.prev_offset.y == off.y
			and self.alignment.prev_anchor_key == key
			and snap
			and (major == nil or (
				snap.mx == major_T.x and snap.my == major_T.y
				and snap.mw == major_T.w and snap.mh == major_T.h))
			and snap.cw == mid_T.w and snap.ch == mid_T.h then
			return
		end

		attach.dirty = true
		self.alignment.prev_anchor_key = key
		self.alignment.prev_type = self.alignment.type

		if anchor.absolute or not attach.host then return end

		if anchor.x == "center" then
			attach.offset.x = 0.5 * major_T.w - mid_T.w / 2 + off.x - mid_T.x + T.x
		end
		if anchor.y == "center" then
			attach.offset.y = 0.5 * major_T.h - mid_T.h / 2 + off.y - mid_T.y + T.y
		end
		if anchor.y == "bottom" then
			attach.offset.y = anchor.inset and (off.y + major_T.h - T.h) or (off.y + major_T.h)
		end
		if anchor.x == "right" then
			attach.offset.x = anchor.inset and (off.x + major_T.w - T.w) or (off.x + major_T.w)
		end
		if anchor.y == "top" then
			attach.offset.y = anchor.inset and off.y or (off.y - T.h)
		end
		if anchor.x == "left" then
			attach.offset.x = anchor.inset and off.x or (off.x - T.w)
		end

		attach.offset.x = attach.offset.x or 0
		attach.offset.y = attach.offset.y or 0

		T.x = major_T.x + attach.offset.x
		T.y = major_T.y + attach.offset.y

		self.alignment.prev_offset = self.alignment.prev_offset or {}
		self.alignment.prev_offset.x, self.alignment.prev_offset.y = off.x, off.y
		self.alignment.prev_snap = {
			key = key,
			ox = off.x, oy = off.y,
			mx = major_T.x, my = major_T.y,
			mw = major_T.w, mh = major_T.h,
			cw = mid_T.w, ch = mid_T.h,
		}
	end

end
