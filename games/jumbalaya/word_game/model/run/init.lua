--[[
	word_game/model/run/init.lua - Run lifecycle facade (State, Scope, Register, Mode, Match, InputLock, Busy)

	Prefer require("word_game.model.run") over deep requires of run submodules.

	Core: none
	Store: none
	Presentation: none
]]

return {
	State = require("word_game.model.run.state"),
	Scope = require("word_game.model.run.scope"),
	Register = require("word_game.model.run.register"),
	Mode = require("word_game.model.run.mode"),
	Match = require("word_game.model.run.match"),
	InputLock = require("word_game.model.run.input_lock"),
	Busy = require("word_game.model.run.busy"),
}
