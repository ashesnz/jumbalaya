--[[
	word_game/model/live_game.lua - Phase 9 model access to the live Game instance.
]]

local BridgeRuntime = require("bridge.runtime")

return function()
	return BridgeRuntime.game()
end
