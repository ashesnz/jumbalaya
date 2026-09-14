--[[
	word_game/model/cards/deck/init.lua - Deck package facade assembling deck submodules

	Core: none
	Store: none
	Presentation: none
]]
-- Package facade for the 52-card letter deck.
--
-- Submodules export closed tables merged here in load order. Cross-module helpers
-- live on deck/shared.lua. Runtime sibling calls use lazy Deck() in submodules.

local Deck = {}
package.loaded["word_game.model.cards.deck"] = Deck

local merge_order = {
	require("word_game.model.cards.deck.identity"),
	require("word_game.model.cards.deck.playability"),
	require("word_game.model.cards.deck.vowels"),
	require("word_game.model.cards.deck.dealing"),
	require("word_game.model.cards.deck.lifecycle"),
	require("word_game.model.cards.deck.jumble"),
	require("word_game.model.cards.deck.letter_modifiers"),
}

for _, mod in ipairs(merge_order) do
	for k, v in pairs(mod) do
		Deck[k] = v
	end
end

Deck.Registry = require("word_game.model.cards.registry")

local TableAreas = require("word_game.model.table_areas")
Deck.dealt_letters = TableAreas.dealt_letters
Deck.draw_pile = TableAreas.draw_pile
Deck.recycle_stash = TableAreas.recycle_stash
Deck.random_wipe_card = (require("word_game.model.cards.registry")).random_wipe_card

return Deck
