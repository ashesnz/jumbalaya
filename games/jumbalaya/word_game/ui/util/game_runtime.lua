--[[
	word_game/ui/util/game_runtime.lua - Phase 9 UI access to the live Game instance.
]]

local BridgeRuntime = require("app.runtime")

local M = {}

function M.game()
	return BridgeRuntime.game()
end

return M
