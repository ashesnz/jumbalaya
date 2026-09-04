--[[
	devtools/panel.lua - Debug tools panel session controller.

	Open/close via Tab (see app/runtime/input_controller.lua). Sections are registered in
	devtools/registry.lua and each provides:
	  register(panel)  - bind button actions
	  build(panel)     - return a layout.section() node
]]
local Kind = require "app.core.object"
local Scheduler = require "app.effects.timeline_scheduler"


local DebugContext = require "devtools.context"
local registry = require "devtools.registry"
local layout = require "devtools.layout"

--- @class DebugPanel : Kind
--- @field game Game
--- @field ctx DebugContext
--- @field ui LayoutView|nil
--- @operator call(Game): DebugPanel
local DebugPanel = Kind:derive("DebugPanel")

--- @param game Game
function DebugPanel:construct(game)
	self.game = game
	self.ctx = DebugContext.new(game)
	self.ui = nil
	self.state = {}
	registry.load_defaults()
end

--- Register a button handler on G.FUNCS with the DT_ prefix.
function DebugPanel:action(name, fn)
	local panel = self
	G.FUNCS["DT_" .. name] = function()
		fn(panel.ctx, panel)
	end
end

function DebugPanel:set_label(key, text)
	self.state[key] = text
	if self.ui then self.ui:recalculate() end
end

function DebugPanel:register_actions()
	local sections = registry.all()
	table.sort(sections, function(a, b) return (a.order or 0) < (b.order or 0) end)
	for _, section in ipairs(sections) do
		if section.register then section.register(self) end
	end
end

function DebugPanel:build_definition()
	local sections = registry.all()
	table.sort(sections, function(a, b) return (a.order or 0) < (b.order or 0) end)

	local content = {}
	for _, section in ipairs(sections) do
		if section.build then
			content[#content + 1] = section.build(self)
		end
	end

	return {n = G.UI.ROOT, config = {align = 'cm', r = 0.1}, nodes = {
		layout.panel_container(content),
	}}
end

function DebugPanel:is_open()
	return self.ui ~= nil and not self.ui.REMOVED
end

function DebugPanel:open()
	if self:is_open() then return end

	self:register_actions()
	self.ui = LayoutView{
		definition = self:build_definition(),
		-- tri = top-right inside room; panel width subtracted so it stays on-screen
		config = {align = 'tri', offset = {x = 6, y = 0.2}, major = G.ROOM_ATTACH, bond = 'Weak'},
	}
	self.game.debug_tools = self.ui

	Scheduler.add{
		blockable = false,
		func = function()
			if self.ui then self.ui.alignment.offset.x = -0.15 end
			return true
		end,
	}
end

function DebugPanel:close()
	if not self.ui then return end
	self.ui:remove()
	self.ui = nil
	self.game.debug_tools = nil
end

function DebugPanel:toggle()
	if self:is_open() then self:close() else self:open() end
end

return DebugPanel
