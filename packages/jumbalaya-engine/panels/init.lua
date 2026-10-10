--[[
	jumbalaya-engine/panels/init.lua - Declarative panel tree (engine UI framework).

	New screens use Panel.column / Panel.button (panels.api). Those compile into
	definition tables for LayoutNode. Game screens compose panels; no Jumbalaya rules.
]]

local RetainedPanel = require("jumbalaya-engine.panels.panel")
require("jumbalaya-engine.panels.container")

local ViewHost = require("jumbalaya-engine.panels.view_host")
local Api = require("jumbalaya-engine.panels.api")

local M = {}

--- Create a panel from a definition tree.
function M.create(args)
	return RetainedPanel(args)
end

M.Panel = RetainedPanel
M.Api = Api
M.ViewHost = ViewHost

for name, value in pairs(Api) do
	if M[name] == nil then
		M[name] = value
	end
end

return M
