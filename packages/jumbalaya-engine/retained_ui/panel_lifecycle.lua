
local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end
return function(Target)
function RetainedPanel:remove()
	if self == g().OVERLAY_MENU then g().REFRESH_ALERTS = true end
	self.root_node:remove()
	local registry = self.config and self.config.instance_type and g().LIVE and g().LIVE[self.config.instance_type] or nil
	if registry then
		for k, v in pairs(registry) do
			if v == self then table.remove(registry, k) end
		end
	end
	teardown_tree(self.children)
	AnimNode.remove(self)
end

function RetainedPanel:draw()
	-- One draw per frame unless a tutorial overlay forces a redraw.
	if self.FRAME.RENDER >= g().FRAMES.RENDER
		and not g().FIRST_PLAY_TUTORIAL_OVERLAY then return end
	self.FRAME.RENDER = g().FRAMES.RENDER

	-- Regular children first (popups/alerts excluded)...
	for k, v in pairs(self.children) do
		if k ~= 'h_popup' and k ~= 'alert' then v:draw() end
	end

	if self.states.visible then
		track_hit_target(self)
		self.root_node:draw_self()
		self.root_node:draw_children()
		-- Explicit draw-layer overrides render after the normal tree.
		for _, v in ipairs(self.draw_layers) do
			if v.draw_self then v:draw_self() else v:draw() end
			if v.draw_children then v:draw_children() end
		end
	end

	if self.children.alert then self.children.alert:draw() end

	self:draw_boundingrect()
end

--- Full relayout from the current definition state. Bumps the major-frame
--- cache generation so weld offsets recompute against the new geometry.
function RetainedPanel:recalculate()
	self:calculate_xywh(self.root_node, self.T, true)
	self.root_node:set_wh()
	self.root_node:set_alignments()
	self.T.w = self.root_node.T.w
	self.T.h = self.root_node.T.h
	g().REFRESH_FRAME_MAJOR_CACHE = (g().REFRESH_FRAME_MAJOR_CACHE or 0) + 1
	self.root_node:initialize_VT()
	g().REFRESH_FRAME_MAJOR_CACHE = (g().REFRESH_FRAME_MAJOR_CACHE > 1 and g().REFRESH_FRAME_MAJOR_CACHE - 1 or nil)
end

function RetainedPanel:move(dt)
	AnimNode.move(self, dt)
	AnimNode.move(self.root_node, dt)
end

function RetainedPanel:drag(offset)
	AnimNode.drag(self, offset)
	AnimNode.move(self.root_node, g().real_dt)
end

function RetainedPanel:add_child(node, parent)
	self:attach_node(node, parent)
	self:recalculate()
end

function RetainedPanel:set_container(container)
	self.root_node:set_container(container)
	Node.set_container(self, container)
end

function RetainedPanel:print_topology(indent)
	local out = '| RetainedPanel | - ID:' .. self.ID .. ' w/h:' .. self.T.w .. '/' .. self.T.h
	out = out .. self.root_node:print_topology(indent or 0)
	return out
end
end
