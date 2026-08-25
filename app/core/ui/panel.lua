--[[ app/core/ui/panel.lua - retained-mode UI tree container (LayoutView) ]]

local AnimNode = require("app.core.scene.animated.init")

---@class LayoutView : AnimNode
---@field definition table
---@field root_node LayoutNode
---@field parent LayoutView|LayoutNode|nil
LayoutView = AnimNode:derive("LayoutView")

function LayoutView:construct(args)
	AnimNode.construct(self, {args.T})

	self.states.drag.can = false
	self.draw_layers = {} -- explicit draw-order overrides (config.draw_layer)

	self.definition = args.definition

	if args.config then
		self.config = args.config
		args.config.major = args.config.major or args.config.parent or self

		self:set_alignment({
			major = args.config.major,
			type = args.config.align or args.config.type or '',
			bond = args.config.bond or 'Strong',
			offset = args.config.offset or {x = 0, y = 0},
		})
		self:set_role{
			xy_bond = args.config.xy_bond,
			r_bond = args.config.r_bond,
			wh_bond = args.config.wh_bond or 'Weak',
			scale_bond = args.config.scale_bond or 'Weak',
		}
		self.states.collide.can =
			(args.config.can_collide == nil) and true or args.config.can_collide

		self.parent = self.config.parent
	end

	-- Build the element tree, measure it, then stretch + align it.
	self:attach_node(self.definition, nil)
	self.Mid = self.Mid or self.root_node
	self:calculate_xywh(self.root_node, self.T)

	self.T.w = self.root_node.T.w
	self.T.h = self.root_node.T.h
	self.root_node:set_wh()
	self.root_node:set_alignments()

	self:align_to_major()
	self.VT.x, self.VT.y = self.T.x, self.T.y
	self.VT.w, self.VT.h = self.T.w, self.T.h

	self.root_node:initialize_VT(true)
	if getmetatable(self) == LayoutView then
		if args.config.instance_type then -- e.g. 'POPUP' for hover/drag popups
			table.insert(G.LIVE[args.config.instance_type], self)
		else
			table.insert(G.LIVE.UIBOX, self)
		end
	end
end

require("app.core.ui.panel_tree")(LayoutView)
require("app.core.ui.panel_layout")(LayoutView)
require("app.core.ui.panel_lifecycle")(LayoutView)

require("app.core.ui.node")

return LayoutView
