--[[
	word_game/model/jumble_play/init.lua - Jumble play-button orchestration.

	`play_jumble_word` evaluates rules and returns a result table.
	UI calls `word_game.ui.play_effects.resolution.resolve` for presentation effects.
]]

local M = {}

require("word_game.model.jumble_play.hand")(M)
require("word_game.model.jumble_play.jumble")(M)

return M
