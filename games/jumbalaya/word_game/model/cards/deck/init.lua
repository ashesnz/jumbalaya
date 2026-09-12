--[[
	word_game/model/cards/deck/init.lua - Deck package facade assembling deck submodules

	Core: none
	Store: none
	Presentation: none
]]
-- Package facade for the 52-card letter deck.
--
-- Initializers run in the same order as the original monolithic module. The
-- private context makes cross-cutting helpers explicit without expanding the
-- public Deck API or introducing globals.

local context = {
	module = {},
}

local Deck = context.module

local initializers = {
		require("word_game.model.cards.deck.identity"),
		require("word_game.model.cards.deck.playability"),
		require("word_game.model.cards.deck.vowels"),
		require("word_game.model.cards.deck.dealing"),
		require("word_game.model.cards.deck.lifecycle"),
		require("word_game.model.cards.deck.jumble"),
		require("word_game.model.cards.deck.letter_modifiers"),
}

for _, initialize in ipairs(initializers) do
	initialize(context)
end

Deck.Registry = require("word_game.model.cards.registry")

local TableAreas = require("word_game.model.table_areas")
Deck.dealt_letters = TableAreas.dealt_letters
Deck.draw_pile = TableAreas.draw_pile
Deck.recycle_stash = TableAreas.recycle_stash
Deck.random_wipe_card = (require("word_game.model.cards.registry")).random_wipe_card

return Deck