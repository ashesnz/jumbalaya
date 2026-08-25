return function(Target)
function LayoutNode:pulse(amount, rot_amt)
	if self.ui_kind == G.UI.OBJECT then
		if self.config.object then self.config.object:pulse(amount, rot_amt) end
	else
		AnimNode.pulse(self, amount, rot_amt)
	end
end

function LayoutNode:can_drag()
	if self.states.drag.can then return self end
	return self.LayoutView:can_drag()
end

function LayoutNode:draw() end

--- Draws children (skipping draw-layer overrides); `draw_after` flips leaf
--- draw order so a leaf renders on top of its own subtree.
function LayoutNode:draw_children(layer)
	if not self.states.visible then return end
	for k, v in pairs(self.children) do
		if not v.config.draw_layer and k ~= 'h_popup' and k ~= 'alert' then
			if v.draw_self and not v.config.draw_after then v:draw_self() else v:draw() end
			if v.draw_children then v:draw_children() end
			if v.draw_self and v.config.draw_after then v:draw_self() else v:draw() end
		end
		if self.children.alert then self.children.alert:draw() end
	end
end
end
