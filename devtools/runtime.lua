--[[ devtools/runtime.lua - Live Game shell accessor for devtools. ]]

local BridgeRuntime = require("bridge.runtime")

local M = {}

function M.game()
	return BridgeRuntime.game()
end

return M
