-- Card identity, presentation, and area primitives for the letter deck.
return function(context)
	local M = context.module

	local function letter_for_index(index)
		return string.char(string.byte("A") + index - 1)
	end

	context.letter_for_index = letter_for_index

	function M.front_key(letter, color)
		if type(letter) ~= "string" or #letter < 1 then return nil end
		if color ~= "red" and color ~= "black" and color ~= "modified" then
			color = "black"
		end
		return color .. "_" .. letter:sub(1, 1):upper()
	end

	function M.front(letter, color)
		local key = M.front_key(letter, color)
		return key and G.P_CARDS and G.P_CARDS[key] or nil
	end

	local function control_for_letter(letter, color)
		return {
			key = M.front_key(letter, color),
			letter = letter,
			letter_color = color,
		}
	end

	function M.control_for_letter(letter, color)
		return control_for_letter(letter, color)
	end

	function M.letter_from_id(letter_id)
		if type(letter_id) ~= "number" or letter_id < 1 or letter_id > 26 then return nil end
		return letter_for_index(letter_id)
	end

	function M.color_from_card(card)
		if card and card.ability and card.ability.letter_color then
			return card.ability.letter_color
		end
		if card and card.config and card.config.card and card.config.card.color then
			return card.config.card.color
		end
		if card and card.base and card.base.color then
			return card.base.color
		end
		return "black"
	end

	function M.tag_card(card, letter, color)
		card.ability.letter = letter
		card.ability.letter_color = color
	end

	function M.is_letter_card(card)
		local letter = card and card.ability and card.ability.letter
		return type(letter) == "string" and #letter == 1
	end

	function M.restore_letter_face(card)
		if not card then return end
		local front = card.config and card.config.card
		if (not front or not front.pos) and card.config and card.config.card_key and G.P_CARDS then
			front = G.P_CARDS[card.config.card_key]
		end
		if (not front or not front.pos) and card.base and card.base.id then
			local letter = card.ability and card.ability.letter
				or (card.config and card.config.card and card.config.card.letter)
				or M.letter_from_id(card.base.id)
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
		if not G.hand or not G.hand.cards then return end
		for i = #G.hand.cards, 1, -1 do
			local card = G.hand.cards[i]
			M.reveal_in_hand(card)
			if not M.is_letter_card(card) then
				G.hand:remove_card(card)
				if card and card.remove then
					card:remove()
				end
			end
		end
	end

	function M.all_areas()
		local areas = { G.deck, G.hand, G.discard }
		if G.placement_table and G.placement_table.area then
			areas[#areas + 1] = G.placement_table.area
		end
		return areas
	end

	function M.iter_cards(fn)
		for _, card in ipairs(G.playing_cards or {}) do
			if card and not card.REMOVED then
				fn(card)
			end
		end
	end

	function M.reset_table_deck()
		if WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.reset then
			WORD_GAME.TableDeck.reset()
		end
		local all = {}
		for _, area in ipairs(M.all_areas()) do
			if area and area.cards then
				for i = #area.cards, 1, -1 do
					local card = area.cards[i]
					if G.placement_table and area == G.placement_table.area then
						G.placement_table:on_remove_card(card)
					end
					area:remove_card(card)
					all[#all + 1] = card
				end
				area:hard_set_cards()
			end
		end

		for _, card in ipairs(all) do
			G.deck:emplace(card)
		end
		G.deck:shuffle("letter_deck_reset")
		G.deck:hard_set_T()
	end

	function M.letter_center()
		local center = G.P_CENTERS and G.P_CENTERS.letter_base
		if center then
			center.atlas = "letter_frame"
			center.pos = { x = 0, y = 0 }
		end
		return center
	end

	function M.create_letter_card(letter, color)
		local LetterPalette = require "word_game.config.letter_card_palette"
		color = color or LetterPalette.DEFAULT_FACE_COLOR
		local front = M.front(letter, color)
		G.playing_card = (G.playing_card or 0) + 1
		local deck_x = (G.deck and G.deck.T and G.deck.T.x) or 0
		local deck_y = (G.deck and G.deck.T and G.deck.T.y) or 0
		local card = Card(
			deck_x, deck_y, G.CARD_W or 1, G.CARD_H or 1.4,
			front,
			M.letter_center(),
			{ playing_card = G.playing_card }
		)
		M.tag_card(card, letter, color)
		G.playing_cards = G.playing_cards or {}
		G.playing_cards[#G.playing_cards + 1] = card
		return card
	end
end
