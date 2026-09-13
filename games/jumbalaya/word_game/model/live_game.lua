--[[
	word_game/model/live_game.lua - Returns live Game instance via jumbalaya-engine.shell

	Core: none
	Store: none
	Presentation: none
]]

local shell = require("jumbalaya-engine.shell")

return function()
	return shell.game()
end
