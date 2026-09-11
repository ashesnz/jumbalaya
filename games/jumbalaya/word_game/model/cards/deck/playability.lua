-- Deck ownership helpers and deal animations (jumble mode; no open-board rerolls).
local live_game = require("word_game.model.live_game")

return function(context)
	local M = context.module
	local core_playability = require("jumbalaya_core.cards.playability")

	local function deck_owns(card)
		return core_playability.deck_owns(card, live_game().draw_pile)
	end

	local function card_letter(card)
		if Dictionary and Dictionary.letter_from_card then
			return Dictionary.letter_from_card(card)
		end
		return card and card.ability and card.ability.letter
	end

	context.deck_owns = deck_owns
	context.card_letter = card_letter

	M.card_letter = card_letter
	M.deck_owns = deck_owns

	function M.deck_letter_counts()
		return core_playability.deck_letter_counts(live_game().draw_pile and live_game().draw_pile.cards, live_game().draw_pile)
	end

	local function placement_cards()
		local area = live_game().pattern_row and live_game().pattern_row.area
		return (area and area.cards) or {}
	end

	context.placement_cards = placement_cards

	local function start_from_pile(card)
		if not card or not live_game().draw_pile then return end
		local x = live_game().draw_pile.T.x + 0.5 * ((live_game().draw_pile.T.w or card.T.w) - card.T.w)
		local y = live_game().draw_pile.T.y + 0.5 * ((live_game().draw_pile.T.h or card.T.h) - card.T.h)
		card.T.x, card.T.y = x, y
		if card.VT then
			card.VT.x, card.VT.y = x, y
		end
		if card.velocity then
			card.velocity.x, card.velocity.y, card.velocity.r = 0, 0, 0
		end
	end

	M.start_from_pile = start_from_pile

	function M.play_deal_slide()
		play_sfx("card_slide1", 1, 0.7)
	end

	local function fly_from_deck_to_hand(card)
		if not card or not live_game().dealt_letters then return false end
		start_from_pile(card)
		live_game().dealt_letters:emplace(card)
		if card.pulse then
			card:pulse(0.18, 0.08)
		end
		M.play_deal_slide()
		M.sync_deck_count_display()
		return true
	end

	context.fly_from_deck_to_hand = fly_from_deck_to_hand
end
