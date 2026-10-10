--[[
	word_game/model/cards/init.lua - Cards domain package facade (LetterTile class, Deck module)

	Core: none
	Store: none
	Presentation: none
]]

local LetterTile = require("word_game.model.cards.letter_tile")

local M = {
	LetterTile = LetterTile,
	Card = LetterTile,
	Deck = require("word_game.model.cards.deck"),
}

require "word_game.model.cards.definitions"

return M