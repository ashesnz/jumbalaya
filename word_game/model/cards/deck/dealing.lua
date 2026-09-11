-- Hand counts plus animated and immediate dealing flows.

local Scheduler = require "app.effects.timeline_scheduler"
return function(context)
	local M = context.module
	local LayoutRequest = require("word_game.model.layout.request")
	local hand_size_cfg = require("word_game.model.hand_size")
	local pile_counts = require("jumbalaya_core.cards.pile_counts")
	local game_access = require("word_game.model.game_access")
	local pile_sync = require("bridge.pile_sync")
	local needs_vowel = context.needs_vowel
	local take_letter_from_deck = context.take_letter_from_deck

	local function placement_count()
		local area = G.pattern_row and G.pattern_row.area
		return (area and area.cards and #area.cards) or 0
	end

	function M.held_count()
		return pile_counts.held_count(
			G.dealt_letters and G.dealt_letters.cards,
			(G.pattern_row and G.pattern_row.area and G.pattern_row.area.cards)
		)
	end

	function M.hand_card_count()
		return pile_counts.hand_card_count(G.dealt_letters and G.dealt_letters.cards)
	end

	function M.draw_pile_count()
		return pile_counts.draw_pile_count(G.draw_pile and G.draw_pile.cards)
	end

	function M.cards_left()
		return M.draw_pile_count()
	end

	function M.sync_deck_count_display()
		local count = M.cards_left()
		G.ARGS = G.ARGS or {}
		G.ARGS.deck_left_count = count
		game_access.patch({ deck_left_count = count })
		pile_sync.sync_areas_to_store()
	end

	M.DEAL_DELAY = 0.14

	function M.deal_one_to_hand(target_size)
		target_size = target_size or hand_size_cfg.get()
		if not G.dealt_letters or M.held_count() >= target_size then return false end
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
		if G.dealt_letters then
			G.dealt_letters.config.card_limit = hand_size_n
			G.dealt_letters.config.selected_limit = hand_size_n
		end
		LayoutRequest.refresh()
		return M.deal_into_hand(hand_size_n, on_complete)
	end

	function M.draw_to_hand(target_size)
		target_size = target_size or hand_size_cfg.get()
		while G.dealt_letters and M.held_count() < target_size do
			local card = take_letter_from_deck(needs_vowel())
			if not card then break end
			G.dealt_letters:emplace(card)
		end
		M.ensure_vowel_in_hand()
		M.ensure_playable_held()
		if G.dealt_letters then
			M.sanitize_hand()
			while M.held_count() < target_size do
				local card = take_letter_from_deck(needs_vowel())
				if not card then break end
				G.dealt_letters:emplace(card)
			end
			M.ensure_vowel_in_hand()
			M.ensure_playable_held()
			G.dealt_letters:set_ranks()
			G.dealt_letters:relayout()
		end
	end
end
