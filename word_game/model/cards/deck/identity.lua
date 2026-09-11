-- Card identity, presentation, and area primitives for the letter deck.
return function(context)
	local M = context.module
	local core_identity = require("jumbalaya_core.cards.identity")
	local core_letter_card = require("jumbalaya_core.cards.letter_card")
	local LetterPalette = require "word_game.config.visuals.letter_card_palette"

	function M.front_key(letter, color)
		return core_identity.front_key(letter, color)
	end

	function M.front(letter, color)
		local key = M.front_key(letter, color)
		return key and G.LETTERS.faces and G.LETTERS.faces[key] or nil
	end

	function M.control_for_letter(letter, color)
		return core_identity.control_for_letter(letter, color)
	end

	function M.letter_from_id(letter_id)
		return core_identity.letter_from_id(letter_id)
	end

	function M.color_from_card(card)
		return core_letter_card.color_from_card(card, {
			modified_color = LetterPalette.MODIFIED_FACE_COLOR,
		})
	end

	function M.tag_card(card, letter, color)
		core_letter_card.tag_ability(card, letter, color)
	end

	function M.is_letter_card(card)
		return core_identity.is_letter_card(card)
	end

	function M.restore_letter_face(card)
		if not card then return end
		local front = card.config and card.config.card
		if (not front or not front.pos) and card.config and card.config.card_key and G.LETTERS.faces then
			front = G.LETTERS.faces[card.config.card_key]
		end
		if not front or not front.pos then
			local letter = card.ability and card.ability.letter
				or (card.config and card.config.card and card.config.card.letter)
				or (card.base and card.base.id and M.letter_from_id(card.base.id))
			local color = M.color_from_card(card)
			if letter then
				front = M.front(letter, color or "black")
			end
		end
		if front and front.pos and card.set_sprites then
			card:set_sprites(card.config and card.config.center, front)
		end
	end

	function M.reveal_in_hand(card)
		if not card then return end
		if not M.is_letter_card(card) and card.base then
			local letter = M.letter_from_id(card.base.id)
				or (card.config and card.config.card and card.config.card.letter)
			local color = M.color_from_card(card)
			if letter then
				M.tag_card(card, letter, color)
			end
		end
		M.restore_letter_face(card)
		card.facing = "front"
		card.sprite_facing = "front"
		card.flipping = nil
		if card.pinch then card.pinch.x = false end
		if card.states then
			card.states.collide.can = true
			card.states.hover.can = true
			card.states.click.can = true
			card.states.drag.can = true
		end
		if card.ability then card.ability.wheel_flipped = nil end
	end

	function M.sanitize_hand()
		if not G.dealt_letters or not G.dealt_letters.cards then return end
		for i = #G.dealt_letters.cards, 1, -1 do
			local card = G.dealt_letters.cards[i]
			M.reveal_in_hand(card)
			if not M.is_letter_card(card) then
				G.dealt_letters:remove_card(card)
				if card and card.remove then
					card:remove()
				end
			end
		end
	end

	function M.all_areas()
		local areas = { G.draw_pile, G.dealt_letters, G.recycle_stash }
		if G.pattern_row and G.pattern_row.area then
			areas[#areas + 1] = G.pattern_row.area
		end
		return areas
	end

	function M.iter_cards(fn)
		for _, card in ipairs(core_letter_card.collect_active_cards(G.letter_inventory)) do
			fn(card)
		end
	end

	function M.reset_table_deck()
		local Presentation = require("word_game.model.presentation")
		Presentation.emit("table_deck_reset")
		require("word_game.model.perks.voucher_discard").reset()
		local all = {}
		for _, area in ipairs(M.all_areas()) do
			if area and area.cards then
				for i = #area.cards, 1, -1 do
					local card = area.cards[i]
					if G.pattern_row and area == G.pattern_row.area then
						G.pattern_row:on_remove_card(card)
					end
					area:remove_card(card)
					all[#all + 1] = card
				end
				area:hard_set_cards()
			end
		end

		for _, card in ipairs(all) do
			G.draw_pile:emplace(card)
		end
		G.draw_pile:shuffle("letter_deck_reset")
		G.draw_pile:hard_set_T()
	end

	function M.letter_center()
		local center = G.LETTERS.centers and G.LETTERS.centers.letter_base
		if center then
			center.atlas = "letter_frame"
			center.pos = { x = 0, y = 0 }
		end
		return center
	end

	function M.create_letter_card(letter, color)
		local LetterPalette = require "word_game.config.visuals.letter_card_palette"
		color = color or LetterPalette.DEFAULT_FACE_COLOR
		local front = M.front(letter, color)
		G.letter_card_id = (G.letter_card_id or 0) + 1
		local deck_x = (G.draw_pile and G.draw_pile.T and G.draw_pile.T.x) or 0
		local deck_y = (G.draw_pile and G.draw_pile.T and G.draw_pile.T.y) or 0
		local card = Card(
			deck_x, deck_y, G.CARD_W or 1, G.CARD_H or 1.4,
			front,
			M.letter_center(),
			{ letter_card_id = G.letter_card_id }
		)
		M.tag_card(card, letter, color)
		G.letter_inventory = G.letter_inventory or {}
		G.letter_inventory[#G.letter_inventory + 1] = card
		return card
	end
end
