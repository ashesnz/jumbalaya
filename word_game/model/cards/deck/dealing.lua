-- Hand counts plus animated and immediate dealing flows.

local Scheduler = require "app.effects.timeline_scheduler"
return function(context)
	local M = context.module
	local Layout = require "word_game.ui.layout"
	local hand_size_cfg = require("word_game.config.hand_size")
	local needs_vowel = context.needs_vowel
	local take_letter_from_deck = context.take_letter_from_deck

	local function placement_count()
		local area = G.placement_table and G.placement_table.area
		return (area and area.cards and #area.cards) or 0
	end

	function M.held_count()
		return ((G.hand and G.hand.cards and #G.hand.cards) or 0) + placement_count()
	end

	function M.hand_card_count()
		return (G.hand and G.hand.cards and #G.hand.cards) or 0
	end

	function M.draw_pile_count()
		if G.deck and G.deck.cards then
			return #G.deck.cards
		end
		return 0
	end

	function M.cards_left()
		return M.draw_pile_count()
	end

	function M.sync_deck_count_display()
		local count = M.cards_left()
		G.ARGS = G.ARGS or {}
		G.ARGS.deck_left_count = count
		if G.GAME then
			G.GAME.deck_left_count = count
		end
	end

	M.DEAL_DELAY = 0.14

	function M.deal_one_to_hand(target_size)
		target_size = target_size or hand_size_cfg.get()
		if not G.hand or M.held_count() >= target_size then return false end
		local card = take_letter_from_deck(needs_vowel())
		if not card then return false end
		return context.fly_from_deck_to_hand(card)
	end

	function M.deal_into_hand(target_size, on_complete)
		target_size = target_size or hand_size_cfg.get()
		local need = math.max(0, target_size - M.held_count())
		local function finish()
			M.ensure_vowel_in_hand()
			M.ensure_playable_held()
			M.sync_deck_count_display()
			if on_complete then on_complete() end
		end
		if need <= 0 then
			finish()
			return 0
		end
		for _ = 1, need do
			Scheduler.add{
				mode = "window",
				delay = M.DEAL_DELAY,
				blocking = true,
				func = function()
					M.deal_one_to_hand(target_size)
					return true
				end,
			}
		end
		Scheduler.add{
			mode = "delayed",
			delay = 0.08,
			blocking = true,
			func = function()
				finish()
				return true
			end,
		}
		return need
	end

	function M.deal_fresh_hand(on_complete)
		local hand_size_n = hand_size_cfg.get()
		if G.hand then
			G.hand.config.card_limit = hand_size_n
			G.hand.config.selected_limit = hand_size_n
		end
		Layout.request_refresh()
		return M.deal_into_hand(hand_size_n, on_complete)
	end

	function M.draw_to_hand(target_size)
		target_size = target_size or hand_size_cfg.get()
		while G.hand and M.held_count() < target_size do
			local card = take_letter_from_deck(needs_vowel())
			if not card then break end
			G.hand:emplace(card)
		end
		M.ensure_vowel_in_hand()
		M.ensure_playable_held()
		if G.hand then
			M.sanitize_hand()
			while M.held_count() < target_size do
				local card = take_letter_from_deck(needs_vowel())
				if not card then break end
				G.hand:emplace(card)
			end
			M.ensure_vowel_in_hand()
			M.ensure_playable_held()
			G.hand:set_ranks()
			G.hand:relayout()
		end
	end
end
