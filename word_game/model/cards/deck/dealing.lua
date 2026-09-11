-- Hand counts plus animated and immediate dealing flows.
local live_game = require("word_game.model.live_game")


local Scheduler = require "app.effects.timeline_scheduler"
return function(context)
	local M = context.module
	local LayoutRequest = require("word_game.model.layout.request")
	local hand_size_cfg = require("word_game.model.hand_size")
	local pile_counts = require("jumbalaya_core.cards.pile_counts")
	local game_access = require("word_game.model.game_access")
	local piles = require("word_game.model.piles")
	local TableAreas = require("word_game.model.table_areas")
	local needs_vowel = context.needs_vowel
	local take_letter_from_deck = context.take_letter_from_deck

	local function placement_count()
		return pile_counts.placement_count(TableAreas.pattern_cards())
	end

	function M.held_count()
		return pile_counts.held_count(TableAreas.hand_cards(), TableAreas.pattern_cards())
	end

	function M.hand_card_count()
		return pile_counts.hand_card_count(TableAreas.hand_cards())
	end

	function M.draw_pile_count()
		return pile_counts.draw_pile_count(TableAreas.draw_cards())
	end

	function M.cards_left()
		return M.draw_pile_count()
	end

	function M.sync_deck_count_display()
		local count = M.cards_left()
		live_game().ARGS = live_game().ARGS or {}
		live_game().ARGS.deck_left_count = count
		game_access.patch({ deck_left_count = count })
	end

	function M.commit_pile_hosts(pile_ids)
		piles.sync_hosts_to_store()
		piles.release_static_chrome(nil, pile_ids)
		M.sync_deck_count_display()
	end

	function M.hydrate_pile_hosts(pile_ids)
		piles.hydrate_hosts_from_store(pile_ids)
	end

	M.DEAL_DELAY = 0.14

	function M.deal_one_to_hand(target_size)
		target_size = target_size or hand_size_cfg.get()
		if not live_game().dealt_letters or M.held_count() >= target_size then return false end
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
			M.commit_pile_hosts({ "hand", "draw" })
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
		if live_game().dealt_letters then
			live_game().dealt_letters.config.card_limit = hand_size_n
			live_game().dealt_letters.config.selected_limit = hand_size_n
		end
		LayoutRequest.refresh()
		return M.deal_into_hand(hand_size_n, on_complete)
	end

	function M.draw_to_hand(target_size)
		target_size = target_size or hand_size_cfg.get()
		while live_game().dealt_letters and M.held_count() < target_size do
			local card = take_letter_from_deck(needs_vowel())
			if not card then break end
			live_game().dealt_letters:emplace(card)
		end
		M.ensure_vowel_in_hand()
		M.ensure_playable_held()
		if live_game().dealt_letters then
			M.sanitize_hand()
			while M.held_count() < target_size do
				local card = take_letter_from_deck(needs_vowel())
				if not card then break end
				live_game().dealt_letters:emplace(card)
			end
			M.ensure_vowel_in_hand()
			M.ensure_playable_held()
			live_game().dealt_letters:set_ranks()
			live_game().dealt_letters:relayout()
			M.commit_pile_hosts({ "hand", "draw" })
		end
	end
end
