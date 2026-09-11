--[[ word_game/model/persistence - Run save/restore and profile progress writes ]]

return {
	RunSave = require("word_game.model.persistence.run_save"),
	Progress = require("word_game.model.persistence.progress"),
	SaveSchema = require("word_game.model.persistence.save_schema"),
}
