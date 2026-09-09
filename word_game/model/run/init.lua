--[[
	word_game/model/run/init.lua - Run lifecycle facade.

	Prefer `require("word_game.model.run")` and `.State`, `.Mode`, etc. over
	deep requires of individual run submodules.
]]

return {
	State = require("word_game.model.run.state"),
	Scope = require("word_game.model.run.scope"),
	Register = require("word_game.model.run.register"),
	Mode = require("word_game.model.run.mode"),
	Match = require("word_game.model.run.match"),
	InputLock = require("word_game.model.run.input_lock"),
}
