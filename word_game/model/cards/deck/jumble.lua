-- Jumble-mode deck: built from Deck.STARTING_LETTERS with recycling replacements.

local Scheduler = require "app.effects.scheduler"
local CardMotion = require "app.effects.card_motion"

return function(context)
	local M = context.module
	local LetterPalette = require "word_game.config.letter_card_palette"

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
			if card and not card.REMOVED and not card.boss_temp and not card.bonus_card then
				G.deck:emplace(card)
			end
		end
		G.deck.config.card_limit = #G.deck.cards
		M.shuffle_deck()
		G.deck:hard_set_T()
		M.sync_deck_count_display()
	end

	function M.clear_hand_and_placement()
		local bonus_stack = require("word_game.ui.boss_word_stack")
		local area = G.placement_table and G.placement_table.area
		if area and area.cards then
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if G.placement_table then
					G.placement_table:on_remove_card(card)
				end
				area:remove_card(card)
				if card.bonus_card then
					bonus_stack.return_card(card)
				elseif card.boss_temp then
					M.destroy_card(card)
				end
			end
			area:hard_set_cards()
		end
		if G.hand and G.hand.cards then
			for i = #G.hand.cards, 1, -1 do
				local card = G.hand.cards[i]
				G.hand:remove_card(card)
				if card.bonus_card then
					bonus_stack.return_card(card)
				elseif card.boss_temp then
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
				if not card.boss_temp and not card.bonus_card then
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
			local card = M.create_letter_card(letter, LetterPalette.DEFAULT_FACE_COLOR)
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

	function M.recycle_discard_into_deck()
		if not G.discard or not G.discard.cards or #G.discard.cards == 0 then
			return false
		end
		for i = #G.discard.cards, 1, -1 do
			local card = G.discard.cards[i]
			G.discard:remove_card(card)
			card.played_pool = nil
			if card.states then
				card.states.visible = true
			end
			G.deck:emplace(card)
		end
		if G.discard.hard_set_cards then
			G.discard:hard_set_cards()
		end
		M.shuffle_deck()
		M.sync_deck_count_display()
		if WORD_GAME and WORD_GAME.TableDiscard and WORD_GAME.TableDiscard.reset then
			WORD_GAME.TableDiscard.reset()
		end
		return true
	end

	function M.needs_jumble_reshuffle()
		if not M.is_jumble_deck() then return false end
		if M.hand_card_count() > 0 then return false end
		if M.draw_pile_count() > 0 then return false end
		local placement = G.placement_table and G.placement_table.area and G.placement_table.area.cards
		if placement and #placement > 0 then return false end
		local discard_count = (G.discard and G.discard.cards and #G.discard.cards) or 0
		return discard_count > 0
	end

	function M.try_jumble_reshuffle_and_deal(on_complete)
		if not M.needs_jumble_reshuffle() then
			if on_complete then on_complete() end
			return false
		end
		if not M.recycle_discard_into_deck() then
			if on_complete then on_complete() end
			return false
		end

		local hand_size = G.TABLE_HAND_SIZE or 7
		local to_deal = math.min(hand_size, #(G.deck.cards or {}))
		local STAGGER = 0.1

		local function finish()
			if G.hand then
				G.hand:set_ranks()
				G.hand:relayout()
				G.hand:snap_VT()
				G.hand:hard_set_cards()
			end
			M.sync_deck_count_display()
			if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.ensure_playable_puzzle then
				WORD_GAME.Jumble.ensure_playable_puzzle()
			end
			G.ARGS = G.ARGS or {}
			G.ARGS.pending_layout = true
			if on_complete then on_complete() end
		end

		if to_deal <= 0 then
			finish()
			return true
		end

		if G.TIMELINE and G.TIMELINE.enqueue then
			for i = 1, to_deal do
				Scheduler.add{
					mode = "window",
					delay = (i - 1) * STAGGER,
					blocking = true,
					func = function()
						local card = G.deck:remove_card()
						if card and G.hand then
							G.deck:emplace(card)
							CardMotion.move{
								from = G.deck,
								to = G.hand,
								percent = 50,
								direction = "up",
								stay_flipped = false,
								card = card,
								delay = 0.08,
							}
						end
						return true
					end,
				}
			end
			Scheduler.add{
				mode = "delayed",
				delay = (to_deal - 1) * STAGGER + 0.25,
				blocking = true,
				func = function()
					finish()
					return true
				end,
			}
			return true
		end

		for _ = 1, to_deal do
			local card = G.deck:remove_card()
			if card and G.hand then
				G.hand:emplace(card)
			end
		end
		finish()
		return true
	end

	function M.deal_jumble_hand()
		if not G.hand then return end
		if WORD_GAME and WORD_GAME.TableDiscard and WORD_GAME.TableDiscard.reset then
			WORD_GAME.TableDiscard.reset()
		end
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
		if M.draw_pile_count() == 0 then
			if M.try_jumble_reshuffle_and_deal() then
				return G.hand.cards and G.hand.cards[#G.hand.cards]
			end
			return nil
		end
		local card = G.deck:remove_card()
		if not card then return nil end
		local function finish()
			if G.hand then
				G.hand:set_ranks()
				G.hand:relayout()
			end
			M.sync_deck_count_display()
		end
		if G.TIMELINE and G.TIMELINE.enqueue then
			Scheduler.add{
				mode = "window",
				delay = 0.05,
				blocking = true,
				func = function()
					CardMotion.move{
						from = G.deck,
						to = G.hand,
						percent = 50,
						direction = "up",
						stay_flipped = false,
						card = card,
						delay = 0.08,
					}
					finish()
					return true
				end,
			}
		elseif context.fly_from_deck_to_hand then
			context.fly_from_deck_to_hand(card)
			finish()
		else
			G.hand:emplace(card)
			finish()
		end
		return card
	end

	function M.discard_from_hand(card)
		if not M.is_jumble_deck() then return false end
		if not card or card.area ~= G.hand or card.REMOVED then return false end
		if card.bonus_card or card.boss_temp then return false end
		if G.GAME and (G.GAME.word_score_animating or G.GAME.hand_redraw_animating
			or G.GAME.hand_shuffle_animating or G.GAME.placement_recall_animating) then
			return false
		end
		local table_discard = WORD_GAME and WORD_GAME.TableDiscard
		if table_discard and table_discard.is_full and table_discard.is_full() then
			return false
		end

		local function after_discard()
			M.draw_jumble_replacement()
			M.sync_deck_count_display()
			if G.hand then
				G.hand:hard_set_cards()
			end
			if G.discard then
				G.discard:relayout()
				G.discard:hard_set_cards()
			end
			if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.sync then
				WORD_GAME.HandShuffle.sync()
			end
			if G.GAME and G.GAME.round_scores then
				G.GAME.round_scores.cards_discarded = G.GAME.round_scores.cards_discarded or { amt = 0 }
				G.GAME.round_scores.cards_discarded.amt = (G.GAME.round_scores.cards_discarded.amt or 0) + 1
			end
		end

		if table_discard and table_discard.record_discard then
			table_discard.record_discard()
		end

		if G.TIMELINE and G.TIMELINE.enqueue then
			CardMotion.move{
				from = G.hand,
				to = G.discard,
				percent = 50,
				direction = "down",
				stay_flipped = false,
				card = card,
				delay = 0.08,
			}
			Scheduler.add{
				mode = "delayed",
				delay = 0.22,
				blocking = true,
				func = function()
					after_discard()
					return true
				end,
			}
		elseif G.hand and G.discard then
			G.hand:remove_card(card)
			G.discard:emplace(card)
			after_discard()
		else
			return false
		end

		play_sfx("card_slide1", 0.9, 0.65)
		return true
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
