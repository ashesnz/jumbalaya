--[[ jumbalaya-engine/panels/panel.lua - Declarative panel tree container (Panel) ]]

local AnimNode = require("jumbalaya-engine.scene.animated.init")

local shell = require("jumbalaya-engine.shell")
local game = shell.game

---@class RetainedPanel : AnimNode
---@field definition table
---@field root_node LayoutNode
---@field parent RetainedPanel|LayoutNode|nil
local RetainedPanel = AnimNode:derive("RetainedPanel")

function RetainedPanel:construct(args)
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

		self:set_scene_parent(self.config.parent)
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
	if getmetatable(self) == RetainedPanel then
		local live = game().LIVE
		local skip_registry = args.config and args.config.skip_live_registry
		if live and not skip_registry then
			local registry_key = (args.config and args.config.instance_type) or "PANELS"
			live[registry_key] = live[registry_key] or {}
			table.insert(live[registry_key], self)
		end
	end
end

require("jumbalaya-engine.panels.panel_tree")(RetainedPanel)
require("jumbalaya-engine.panels.panel_layout")(RetainedPanel)
require("jumbalaya-engine.panels.panel_lifecycle")(RetainedPanel)

require("jumbalaya-engine.panels.node")

return RetainedPanel
