--[[
	word_game/model/cards/deck/letter_modifiers.lua - Marketplace modified-letter apply/sync and deck membership checks

	Core: jumbalaya_core.cards.letter_modifiers, jumbalaya_core.cards.letter_card
	Store: none
	Presentation: none
]]
-- Per-letter marketplace modifiers for deck cards (A–Z).
local live_game = require("word_game.model.live_game")

return function(context)
	local M = context.module
	local LetterPalette = require "word_game.config.visuals.letter_card_palette"
	local core_modifiers = require("jumbalaya_core.cards.letter_modifiers")
	local core_letter_card = require("jumbalaya_core.cards.letter_card")

	M.LETTER_MODIFIERS = core_modifiers.LETTER_MODIFIERS
	M.modifier_description = core_modifiers.modifier_description
	M.modifier_ui_text = core_modifiers.modifier_ui_text
	M.card_letter = core_modifiers.card_letter
	M.is_modified = core_modifiers.is_modified
	M.modified_cards_in = core_modifiers.modified_cards_in
	M.has_modified_letter = core_modifiers.has_modified_letter

	local function sync_modified_face(card)
		local letter = M.card_letter(card)
		if not letter then return end
		local color = LetterPalette.MODIFIED_FACE_COLOR
		M.tag_card(card, letter, color)
		local front = M.front(letter, color)
		if front and card.apply_face then
			card:apply_face(front, false)
		elseif front and card.set_sprites then
			card:set_sprites(card.config and card.config.center, front)
		end
	end

	function M.apply_to_card(card)
		if not card or not card.ability then return false end
		if M.is_modified(card) then return false end
		card.ability.modified = true
		card.edition = nil
		sync_modified_face(card)
		return true
	end

	function M.deck_has_modified_letter(letter)
		letter = letter and letter:upper()
		for _, card in ipairs(core_letter_card.collect_active_cards(live_game().letter_inventory)) do
			if M.is_modified(card) and M.card_letter(card) == letter then
				return true
			end
		end
		return false
	end
end
