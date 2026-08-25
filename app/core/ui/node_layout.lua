return function(Target)
function LayoutNode:set_wh()
	local padding = (self.config and self.config.padding) or G.UI.padding

	if next(self.children) == nil or self.config.no_fill then
		return self.T.w, self.T.h
	end

	local max_w, max_h = 0, 0
	for _, w in pairs(self.children) do
		if w.set_wh then
			local cw, ch = w:set_wh()
			if cw and ch then
				if cw > max_w then max_w = cw end
				if ch > max_h then max_h = ch end
			else
				max_w = padding
				max_h = padding
			end
		end
	end
	for _, w in pairs(self.children) do
		if w.ui_kind == G.UI.ROW then w.T.w = max_w end
		if w.ui_kind == G.UI.COLUMN then w.T.h = max_h end
	end

	return self.T.w, self.T.h
end

--- Shifts this subtree's role offsets by (x, y) — the mechanism behind
--- alignment chars.
function LayoutNode:align(x, y)
	self.role.offset.y = self.role.offset.y + y
	self.role.offset.x = self.role.offset.x + x
	for _, v in pairs(self.children) do
		if v.align then v:align(x, y) end
	end
end

--- Applies our config.align to each child (c/m/b/r chars), then recurses.
function LayoutNode:set_alignments()
	for _, v in pairs(self.children) do
		if self.config and self.config.align and v.align then
			local padding = self.config.padding or G.UI.padding
			-- Leaves center within our full box; containers within our content box.
			if string.find(self.config.align, 'c') then
				if v.ui_kind == G.UI.TEXT or v.ui_kind == G.UI.BOX or v.ui_kind == G.UI.OBJECT then
					v:align(0, 0.5 * (self.T.h - 2 * padding - v.T.h))
				else
					v:align(0, 0.5 * (self.T.h - self.content_dimensions.h))
				end
			end
			if string.find(self.config.align, 'm') then
				v:align(0.5 * (self.T.w - self.content_dimensions.w), 0)
			end
			if string.find(self.config.align, 'b') then
				v:align(0, self.T.h - self.content_dimensions.h)
			end
			if string.find(self.config.align, 'r') then
				v:align(self.T.w - self.content_dimensions.w, 0)
			end
		end
		if v.set_alignments then v:set_alignments() end
	end
end

--- Keeps bound text current: lazily builds the drawable, refreshes it when
--- ref_table[ref_value] changes, recalculating the box when length changes.
function LayoutNode:update_text()
	if self.config and self.config.text and not self.config.text_drawable then
		self.config.lang = self.config.lang or G.LANG
		local font_obj = self.config.font or (self.config.lang and self.config.lang.font)
		if love.graphics and love.graphics.newText and font_obj and font_obj.FONT then
			self.config.text_drawable = love.graphics.newText(font_obj.FONT, {G.C.WHITE, self.config.text})
		end
	end

	if self.config.ref_table and self.config.ref_table[self.config.ref_value] ~= self.config.prev_value then
		self.config.text = tostring(self.config.ref_table[self.config.ref_value])
		if self.config.text_drawable and self.config.text_drawable.set then
			self.config.text_drawable:set(self.config.text)
		end
		if not self.config.no_recalc and self.config.prev_value
			and string.len(self.config.prev_value) ~= string.len(self.config.text) then
			self.LayoutView:recalculate()
		end
		self.config.prev_value = self.config.ref_table[self.config.ref_value]
	end
end

--- Keeps embedded objects current: hot-swaps via ref bindings, mirrors hover
--- state between host and object, and handles object-initiated relayouts.
function LayoutNode:update_object()
	if self.config.ref_table and self.config.ref_value
		and self.config.ref_table[self.config.ref_value] ~= self.config.object then
		self.config.object = self.config.ref_table[self.config.ref_value]
		self.LayoutView:recalculate()
	end

	if self.config.object then
		self.config.object.config.refresh_movement = true
		if self.config.object.states.hover.is and not self.states.hover.is then
			self:hover()
			self.states.hover.is = true
		end
		if not self.config.object.states.hover.is and self.states.hover.is then
			self:stop_hover()
			self.states.hover.is = false
		end
	end

	if self.config.object and self.config.object.ui_object_updated then
		self.config.object.ui_object_updated = nil
		self.config.object.parent = self
		self.config.object:set_role(self.config.role or {role_type = 'Minor', major = self})
		self.config.object:move_with_major(0)
		if self.config.object.non_recalc then
			-- Manual placement: adjust the parent's content box instead of a
			-- full relayout (used by high-frequency readouts).
			self.parent.content_dimensions.w = self.config.object.T.w
			self:align(self.parent.T.x - self.config.object.T.x, self.parent.T.y - self.config.object.T.y)
			self.parent:set_alignments()
		else
			self.LayoutView:recalculate()
		end
	end
end
end
