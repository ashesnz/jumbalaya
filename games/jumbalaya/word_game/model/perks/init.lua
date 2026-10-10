--[[
	word_game/model/perks/init.lua - Perks package facade (Registry, Effects, DiscardBin)

	Core: none
	Store: none
	Presentation: none
]]

return {
	Registry = require("word_game.model.perks.registry"),
	Effects = require("word_game.model.perks.effects"),
	DiscardBin = require("word_game.model.perks.discard_bin"),
}
