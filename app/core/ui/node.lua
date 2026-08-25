--[[ app/core/ui/node.lua - one node in a LayoutView tree (LayoutNode) ]]

local AnimNode = require("app.core.scene.animated.init")

---@class LayoutNode : AnimNode
---@field parent LayoutView|LayoutNode|nil
---@field ui_kind integer
---@field LayoutView LayoutView
LayoutNode = AnimNode:derive("LayoutNode")
LayoutNode = LayoutNode

-- NOTE: constructed function-style (no colon) from LayoutView:attach_node.
function LayoutNode:construct(parent, new_UIBox, new_ui_kind, config)
	self.parent = parent
	self.ui_kind = new_ui_kind
	self.LayoutView = new_UIBox
	self.config = config or {}
	if self.config and self.config.object then self.config.object.parent = self end
	self.children = {}
	self.ARGS = self.ARGS or {}
	self.content_dimensions = {w = 0, h = 0}
end

require("app.core.ui.node_values")(LayoutNode)
require("app.core.ui.node_topology")(LayoutNode)
require("app.core.ui.node_draw")(LayoutNode)
require("app.core.ui.node_layout")(LayoutNode)
require("app.core.ui.node_vertices")(LayoutNode)
require("app.core.ui.node_render_content")(LayoutNode)
require("app.core.ui.node_render_decor")(LayoutNode)
require("app.core.ui.node_interaction")(LayoutNode)

return LayoutNode
