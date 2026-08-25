return function(Target)
function LayoutNode:print_topology(indent)
	local uit_name = '????'
	for k, v in pairs(G.UI) do
		if v == self.ui_kind then uit_name = '' .. k end
	end
	local out = '\n' .. string.rep('  ', indent or 0) .. '| ' .. uit_name .. ' | - ID:' .. self.ID .. ' w/h:' .. self.T.w .. '/' .. self.T.h
	if uit_name == 'O' then
		out = out .. ' OBJ:' .. (
			getmetatable(self.config.object) == CardArea and 'CardArea' or
			getmetatable(self.config.object) == Card and 'Card' or
			getmetatable(self.config.object) == LayoutView and 'LayoutView' or
			getmetatable(self.config.object) == Particles and 'Particles' or
			getmetatable(self.config.object) == FlowText and 'FlowText' or
			getmetatable(self.config.object) == Sprite and 'Sprite' or
			getmetatable(self.config.object) == SpriteAnimator and 'SpriteAnimator' or
			'OTHER')
	elseif uit_name == 'T' then
		out = out .. ' TEXT:' .. (self.config.text or 'REF')
	end

	for _, v in ipairs(self.children) do
		if v.print_topology then out = out .. v:print_topology((indent or 0) + 1) end
	end
	return out
end

--- Snap the freshly-laid-out tree onto its transforms and sync embedded
--- objects. Capability-guarded so plain Moveables work as objects too.
function LayoutNode:initialize_VT()
	self:move_with_major(0)
	self:calculate_parallax()

	for _, v in pairs(self.children) do
		if v.initialize_VT then v:initialize_VT() end
	end

	self.VT.w, self.VT.h = self.T.w, self.T.h

	if self.ui_kind == G.UI.TEXT then self:update_text() end
	if self.config.object then
		if not self.config.no_role then
			if self.config.object.hard_set_T then
				self.config.object:hard_set_T(self.T.x, self.T.y, self.T.w, self.T.h)
			end
			if self.config.object.move_with_major then
				self.config.object:move_with_major(0)
			end
			if self.config.object.alignment and self.config.object.align_to_major then
				self.config.object.alignment.prev_type = ''
				self.config.object:align_to_major()
			end
		end
		if self.config.object.recalculate then
			self.config.object:recalculate()
		end
	end
end
end
