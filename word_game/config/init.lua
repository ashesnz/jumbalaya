--[[
	word_game/config/init.lua - Static tuning facade.

	Prefer subpackage paths (`config.gameplay.round`, etc.) for new code.
]]

return {
	Boot = {
		Runtime = require("word_game.config.boot.runtime"),
		Options = require("word_game.config.boot.runtime_options"),
		Env = require("word_game.config.boot.env"),
	},
	Layout = require("word_game.config.layout.dimensions"),
	Visuals = {
		Palette = require("word_game.config.visuals.palette"),
		LetterCard = require("word_game.config.visuals.letter_card_palette"),
		DeckFaceColors = require("word_game.config.visuals.deck_face_colors"),
	},
	Gameplay = {
		Round = require("word_game.config.gameplay.round"),
		Economy = require("word_game.config.gameplay.economy"),
		RunParams = require("word_game.config.gameplay.run_params"),
	},
	Perks = require("word_game.config.perks"),
	Jumble = require("word_game.config.jumble"),
}
