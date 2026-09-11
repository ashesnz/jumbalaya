--[[
	jumbalaya-engine/panels/init.lua - Declarative panel tree (engine UI framework).

	Builds layout trees from definition tables (ROOT / ROW / COLUMN / TEXT / BUTTON).
	Game screens in word_game/ui/ compose these panels; this package has no Jumbalaya rules.
]]

local Panel = require("jumbalaya-engine.panels.panel")
require("jumbalaya-engine.panels.container")

local ViewHost = require("jumbalaya-engine.panels.view_host")

local M = {}

--- Create a panel from a definition tree.
function M.create(args)
	return Panel(args)
end

M.Panel = Panel
---@deprecated Use M.Panel — alias kept for incremental migration.
M.RetainedPanel = Panel
M.ViewHost = ViewHost

return M
