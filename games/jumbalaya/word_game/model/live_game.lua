--[[
	word_game/model/live_game.lua - Returns live Game instance via app.runtime bridge

	Core: none
	Store: none
	Presentation: none
]]

local BridgeRuntime = require("app.runtime")

return function()
	return BridgeRuntime.game()
end
