--[[
	word_game/model/persistence/init.lua - Persistence package facade (RunSave, Progress, SaveSchema)

	Core: none
	Store: none
	Presentation: none
]]

return {
	RunSave = require("word_game.model.persistence.run_save"),
	Progress = require("word_game.model.persistence.progress"),
	SaveSchema = require("word_game.model.persistence.save_schema"),
}
