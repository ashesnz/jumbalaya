-- Held-card accounting and playable-hand rerolls.
local live_game = require("word_game.model.live_game")

return function(context)
	local M = context.module
	local hand_size_cfg = require("word_game.model.hand_size")
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

	local function held_cards()
		local out = {}
		if live_game().dealt_letters and live_game().dealt_letters.cards then
			for _, card in ipairs(live_game().dealt_letters.cards) do
				out[#out + 1] = card
			end
		end
		for _, card in ipairs(placement_cards()) do
			out[#out + 1] = card
		end
		return out
	end

	local function held_letter_counts()
		if not Dictionary then return {} end
		return Dictionary.counts_from_cards(held_cards())
	end

	context.placement_cards = placement_cards
	context.held_cards = held_cards
	context.held_letter_counts = held_letter_counts

	local function should_ensure_playable()
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active() then
			return false
		end
		return true
	end

	function M.held_is_playable()
		if not Dictionary then return true end
		if M.held_count() < hand_size_cfg.get() then return true end
		return Dictionary.has_playable_word(held_letter_counts())
	end

	local function swap_priority(card)
		return core_playability.swap_priority(card)
	end

	local function deck_pool_cards()
		local out = {}
		for _, card in ipairs(live_game().draw_pile and live_game().draw_pile.cards or {}) do
			if deck_owns(card) then
				out[#out + 1] = card
			end
		end
		return out
	end

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
		if M.commit_pile_hosts then
			M.commit_pile_hosts({ "hand", "draw" })
		else
			M.sync_deck_count_display()
		end
		return true
	end

	context.fly_from_deck_to_hand = fly_from_deck_to_hand

	local function swap_held_with_deck(held_card, deck_card)
		if not held_card or not deck_card or not live_game().draw_pile then return false end
		local area = held_card.area
		if not area then return false end

		area:remove_card(held_card)
		live_game().draw_pile:remove_card(deck_card)
		live_game().draw_pile:emplace(held_card)

		if area == live_game().dealt_letters then
			fly_from_deck_to_hand(deck_card)
			M.reveal_in_hand(deck_card)
		else
			area:emplace(deck_card)
			M.reveal_in_hand(deck_card)
		end
		return true
	end

	local function align_held()
		if live_game().dealt_letters then
			live_game().dealt_letters:set_ranks()
			live_game().dealt_letters:relayout()
		end
		if live_game().pattern_row then
			live_game().pattern_row:relayout()
		end
	end

	--- Reroll held cards against the deck until a playable subset exists.
	function M.ensure_playable_held()
		if not Dictionary or not should_ensure_playable() then return true end
		Dictionary.load()

		local target = hand_size_cfg.get()
		if M.held_count() < target then return true end
		if Dictionary.has_playable_word(held_letter_counts()) then return true end

		local held = held_cards()
		table.sort(held, function(a, b)
			return swap_priority(a) > swap_priority(b)
		end)

		local pool = deck_pool_cards()
		for _, hcard in ipairs(held) do
			local hletter = card_letter(hcard)
			if hletter then
				local base = held_letter_counts()
				for _, dcard in ipairs(pool) do
					local dletter = card_letter(dcard)
					if dletter then
						local trial = core_playability.trial_letter_swap(base, hletter, dletter)
						if Dictionary.has_playable_word(trial) then
							if swap_held_with_deck(hcard, dcard) then
								align_held()
								return true
							end
						end
					end
				end
			end
		end

		-- Greedy rerolls if no single swap worked.
		held = held_cards()
		table.sort(held, function(a, b)
			return swap_priority(a) > swap_priority(b)
		end)
		for _ = 1, 52 do
			if Dictionary.has_playable_word(held_letter_counts()) then
				align_held()
				return true
			end
			local hcard = held[1]
			if not hcard or not hcard.area or not live_game().draw_pile or #live_game().draw_pile.cards == 0 then
				break
			end
			local area = hcard.area
			area:remove_card(hcard)
			live_game().draw_pile:emplace(hcard)
			local replacement = context.take_letter_from_deck(false)
			if not replacement then
				live_game().draw_pile:remove_card(hcard)
				area:emplace(hcard)
				break
			end
			if area == live_game().dealt_letters then
				fly_from_deck_to_hand(replacement)
			else
				area:emplace(replacement)
			end
			M.reveal_in_hand(replacement)
			held = held_cards()
			table.sort(held, function(a, b)
				return swap_priority(a) > swap_priority(b)
			end)
		end

		align_held()
		return Dictionary.has_playable_word(held_letter_counts())
	end
end
