--[[
	bridge/event_bridge.lua - Forward Presentation.emit to engine EventBus (Phase 6).
]]

local Presentation = require("word_game.model.presentation")

local M = {}

function M.install(engine)
	if not engine or not engine.events then return end
	Presentation.bind_events(engine.events)
end

return M
