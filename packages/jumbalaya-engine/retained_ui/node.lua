--[[ app/core/ui/node.lua - one node in a RetainedPanel tree (LayoutNode) ]]

local AnimNode = require("app.core.scene.animated.init")

---@class LayoutNode : AnimNode
---@field parent RetainedPanel|LayoutNode|nil
---@field ui_kind integer
---@field panel RetainedPanel
LayoutNode = AnimNode:derive("LayoutNode")
LayoutNode = LayoutNode

-- NOTE: constructed function-style (no colon) from RetainedPanel:attach_node.
function LayoutNode:construct(parent, new_UIBox, new_ui_kind, config)
	self.parent = parent
	self.ui_kind = new_ui_kind
	self.panel = new_UIBox
	self.config = config or {}
	if self.config and self.config.object then self.config.object.parent = self end
	self.children = {}
	self.ARGS = self.ARGS or {}
	self.content_dimensions = {w = 0, h = 0}
end

require("jumbalaya-engine.retained_ui.node_values")(LayoutNode)
require("jumbalaya-engine.retained_ui.node_topology")(LayoutNode)
require("jumbalaya-engine.retained_ui.node_draw")(LayoutNode)
require("jumbalaya-engine.retained_ui.node_layout")(LayoutNode)
require("jumbalaya-engine.retained_ui.node_vertices")(LayoutNode)
require("jumbalaya-engine.retained_ui.node_render_content")(LayoutNode)
require("jumbalaya-engine.retained_ui.node_render_decor")(LayoutNode)
require("jumbalaya-engine.retained_ui.node_interaction")(LayoutNode)

return LayoutNode
