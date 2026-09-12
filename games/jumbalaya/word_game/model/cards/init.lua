--[[
	word_game/model/cards/init.lua - Cards domain package facade (Card class, Deck module)

	Core: none
	Store: none
	Presentation: none
]]
-- Jumbalaya card-domain package: definitions and deck behavior.

local M = {
	Card = require("word_game.model.cards.card"),
	Deck = require("word_game.model.cards.deck"),
}

require "word_game.model.cards.definitions"

return M