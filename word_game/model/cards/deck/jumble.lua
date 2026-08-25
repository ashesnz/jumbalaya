-- Jumble-mode deck: built from Deck.STARTING_LETTERS with recycling replacements.

local Scheduler = require "app.effects.scheduler"
local CardMotion = require "app.effects.card_motion"

return function(context)
	local M = context.module

	function M.is_jumble_deck()
		local wr = G.GAME and G.GAME.word_round
		return wr and wr.mode == "jumble"
	end

	local function purge_table_cards()
		local function purge(area)
			if not area or not area.cards then return end
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if G.placement_table and area == G.placement_table.area then
					G.placement_table:on_remove_card(card)
				end
				area:remove_card(card)
			end
			if area.hard_set_cards then
				area:hard_set_cards()
			end
		end
		purge(G.hand)
		purge(G.discard)
		purge(G.placement_table and G.placement_table.area)
	end

	function M.populate_jumble_deck()
		purge_table_cards()
		if #(G.playing_cards or {}) == 0 then
			M.populate_starting_deck()
			return
		end
		G.deck.cards = {}
		for _, card in ipairs(G.playing_cards) do
			if card and not card.REMOVED and not card.boss_temp then
				G.deck:emplace(card)
			end
		end
		G.deck.config.card_limit = #G.deck.cards
		M.shuffle_deck()
		G.deck:hard_set_T()
		M.sync_deck_count_display()
	end

	function M.clear_hand_and_placement()
		local area = G.placement_table and G.placement_table.area
		if area and area.cards then
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if G.placement_table then
					G.placement_table:on_remove_card(card)
				end
				area:remove_card(card)
				if card.boss_temp then
					M.destroy_card(card)
				end
			end
			area:hard_set_cards()
		end
		if G.hand and G.hand.cards then
			for i = #G.hand.cards, 1, -1 do
				local card = G.hand.cards[i]
				G.hand:remove_card(card)
				if card.boss_temp then
					M.destroy_card(card)
				end
			end
		end
	end

	function M.destroy_boss_cards()
		local j = G.GAME and G.GAME.word_round and G.GAME.word_round.jumble
		if not j or not j.boss_cards then return end
		for _, card in ipairs(j.boss_cards) do
			if card and not card.REMOVED then
				if card.area then
					card.area:remove_card(card)
				end
				M.destroy_card(card)
			end
		end
		j.boss_cards = nil
	end

	function M.return_hand_to_deck(on_complete, opts)
		opts = opts or {}
		local cards = {}
		if G.hand and G.hand.cards then
			for _, card in ipairs(G.hand.cards) do
				if not card.boss_temp then
					cards[#cards + 1] = card
				end
			end
		end
		if #cards == 0 then
			if on_complete then on_complete() end
			return
		end
		if opts.instant then
			for _, card in ipairs(cards) do
				G.hand:remove_card(card)
				G.deck:emplace(card)
			end
			M.shuffle_deck()
			M.sync_deck_count_display()
			if on_complete then on_complete() end
			return
		end
		for i, card in ipairs(cards) do
			if G.TIMELINE and G.TIMELINE.enqueue then
				Scheduler.add{
					mode = "window",
					delay = (i - 1) * 0.08,
					blocking = true,
					func = function()
						CardMotion.move{from = G.hand, to = G.deck, percent = 50, direction = "down", stay_flipped = false, card = card, delay = 0.1}
						return true
					end,
				}
			elseif G.hand and G.deck then
				G.hand:remove_card(card)
				G.deck:emplace(card)
			end
		end
		if G.TIMELINE and G.TIMELINE.enqueue then
			Scheduler.add{
				mode = "delayed",
				delay = #cards * 0.08 + 0.25,
				blocking = true,
				func = function()
					M.shuffle_deck()
					M.sync_deck_count_display()
					if on_complete then on_complete() end
					return true
				end,
			}
		elseif on_complete then
			on_complete()
		end
	end

	function M.deal_boss_hand(letters, on_complete, opts)
		opts = opts or {}
		local stagger = opts.fast and 0.04 or 0.1
		local finish_delay = opts.fast and 0.06 or 0.2
		if not G.hand or not letters or #letters == 0 then
			if on_complete then on_complete() end
			return
		end
		M.clear_hand_and_placement()
		local j = G.GAME and G.GAME.word_round and G.GAME.word_round.jumble
		j.boss_cards = {}
		for i, letter in ipairs(letters) do
			local card = M.create_letter_card(letter, "red")
			card.boss_temp = true
			for pi = #(G.playing_cards or {}), 1, -1 do
				if G.playing_cards[pi] == card then
					table.remove(G.playing_cards, pi)
					break
				end
			end
			j.boss_cards[#j.boss_cards + 1] = card
			G.deck:emplace(card)
			if G.TIMELINE and G.TIMELINE.enqueue then
				Scheduler.add{
					mode = "window",
					delay = (i - 1) * stagger,
					blocking = true,
					func = function()
						CardMotion.move{from = G.deck, to = G.hand, percent = 50, direction = "up", stay_flipped = false, card = card, delay = 0.08}
						return true
					end,
				}
			elseif context.fly_from_deck_to_hand then
				context.fly_from_deck_to_hand(card)
			else
				G.deck:remove_card(card)
				G.hand:emplace(card)
			end
		end
		local finish = function()
			local j = G.GAME and G.GAME.word_round and G.GAME.word_round.jumble
			if not (j and j.boss_puzzle_hidden)
				and G.placement_table and G.placement_table.apply_screen_position then
				G.placement_table:apply_screen_position()
			end
			if G.hand then
				G.hand:set_ranks()
				G.hand:relayout()
				G.hand:snap_VT()
				G.hand:hard_set_cards()
			end
			M.sync_deck_count_display()
			if on_complete then on_complete() end
		end
		if G.TIMELINE and G.TIMELINE.enqueue then
			Scheduler.add{
				mode = "delayed",
				delay = #letters * stagger + finish_delay,
				blocking = true,
				func = function()
					finish()
					return true
				end,
			}
		else
			finish()
		end
	end

	function M.deal_jumble_hand()
		if not G.hand then return end
		M.clear_hand_and_placement()
		local hand_size = G.TABLE_HAND_SIZE or 7
		local to_deal = math.min(hand_size, #(G.deck.cards or {}))
		for _ = 1, to_deal do
			local card = G.deck:remove_card()
			if card then
				G.hand:emplace(card)
			end
		end
		G.hand:set_ranks()
		G.hand:relayout()
		G.hand:snap_VT()
		G.hand:hard_set_cards()
		M.sync_deck_count_display()
		if WORD_GAME and WORD_GAME.Jumble then
			WORD_GAME.Jumble.ensure_playable_puzzle()
		end
	end

	function M.draw_jumble_replacement()
		if not G.hand then return nil end
		local card = G.deck:remove_card()
		if not card then return nil end
		if context.fly_from_deck_to_hand then
			context.fly_from_deck_to_hand(card)
		else
			G.hand:emplace(card)
			G.hand:set_ranks()
			G.hand:relayout()
			M.sync_deck_count_display()
		end
		return card
	end

	function M.refill_jumble_held(target_size)
		target_size = target_size or G.TABLE_HAND_SIZE or 7
		while M.held_count() < target_size do
			if not M.draw_jumble_replacement() then break end
		end
		if G.hand then
			G.hand:set_ranks()
			G.hand:relayout()
		end
		require("word_game.ui.layout").request_refresh()
	end
end
