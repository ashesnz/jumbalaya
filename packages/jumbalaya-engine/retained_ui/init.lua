--[[
	jumbalaya-engine/retained_ui/init.lua - Retained-mode UI tree (Phase 8).
]]

local RetainedPanel = require("jumbalaya-engine.retained_ui.panel")
require("jumbalaya-engine.retained_ui.container")

local M = {}

--- Create a retained UI panel from a definition tree.
function M.create(args)
	return RetainedPanel(args)
end

M.RetainedPanel = RetainedPanel

return M
