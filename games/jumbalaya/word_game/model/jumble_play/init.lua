--[[
	word_game/model/jumble_play/init.lua - Jumble play facade (Rules, ModifierEffects, play_jumble_word, hand-clear)

	UI calls word_game.ui.play_effects.resolution.resolve for play cinematics.

	Core: none
	Store: none
	Presentation: none
]]

local M = {}

M.Rules = require("word_game.model.jumble_play.jumble_rules")
M.ModifierEffects = require("word_game.model.jumble_play.letter_modifier_effects")

require("word_game.model.jumble_play.hand")(M)
require("word_game.model.jumble_play.jumble")(M)

return M
