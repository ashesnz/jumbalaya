--[[
	word_game/model/cards/deck/jumble.lua - Jumble deal, draw, reshuffle, and refill.

	Core: jumbalaya_core.cards.letter_card
	Store: pile hosts via piles; deck_left_count patches
	Presentation: deal animations via Scheduler; layout_refresh via LayoutRequest
]]
local live_game = require("word_game.model.live_game")


local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local CardMotion = require "word_game.ui.effects.card_motion"
local hand_size_cfg = require("word_game.model.hand_size")

return function(context)
	local M = context.module
	local LetterPalette = require "word_game.config.visuals.letter_card_palette"
	local bonus_return = require("word_game.model.jumble.bonus_return")
	local voucher_discard = require("word_game.model.perks.voucher_discard")
	local Presentation = require("word_game.model.presentation")
	local deal_boss_hand = require("word_game.model.cards.deck.boss_hand")(M, context)
	local core_letter_card = require("jumbalaya_core.cards.letter_card")
	local game_access = require("word_game.model.game_access")
	local piles = require("word_game.model.piles")
	local TableAreas = require("word_game.model.table_areas")
	local LayoutRequest = require("word_game.model.layout.request")

	local function commit_piles(pile_ids)
		if M.commit_pile_hosts then
			M.commit_pile_hosts(pile_ids)
		else
			M.sync_deck_count_display()
		end
	end

	function M.is_jumble_deck()
		local wr = game_access.word_round()
		return wr and wr.mode == "jumble"
	end

	local function reset_deck_pile()
		if not live_game().draw_pile then return end
		if live_game().draw_pile.cards then
			for i = #live_game().draw_pile.cards, 1, -1 do
				local card = live_game().draw_pile.cards[i]
				if card and card.remove_from_area then
					card:remove_from_area()
				end
			end
			live_game().draw_pile.cards = {}
		end
		if live_game().draw_pile.hard_set_cards then
			live_game().draw_pile:hard_set_cards()
		end
	end

	local function purge_table_cards()
		local function purge(area)
			if not area or not area.cards or not area.remove_card then return end
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if live_game().pattern_row and area == live_game().pattern_row.area then
					live_game().pattern_row:on_remove_card(card)
				end
				area:remove_card(card)
			end
			if area.hard_set_cards then
				area:hard_set_cards()
			end
		end
		purge(live_game().dealt_letters)
		purge(live_game().recycle_stash)
		purge(live_game().pattern_row and live_game().pattern_row.area)
	end

	function M.populate_jumble_deck()
		purge_table_cards()
		if #(live_game().letter_inventory or {}) == 0 then
			M.populate_starting_deck()
			return
		end
		reset_deck_pile()
		for _, card in ipairs(live_game().letter_inventory) do
			if core_letter_card.is_jumble_draw_candidate(card) then
				if card.remove_from_area then
					card:remove_from_area()
				end
				card.played_pool = nil
				card.discard_stash = nil
				if card.states then
					card.states.visible = true
				end
				if live_game().draw_pile.emplace then
					live_game().draw_pile:emplace(card)
				end
			end
		end
		if live_game().draw_pile.config then
			live_game().draw_pile.config.card_limit = #live_game().draw_pile.cards
		end
		M.shuffle_deck()
		if live_game().draw_pile.hard_set_T then
			live_game().draw_pile:hard_set_T()
		end
		commit_piles({ "hand", "draw", "discard", "pattern" })
	end

	function M.clear_hand_and_placement()
		local area = live_game().pattern_row and live_game().pattern_row.area
		if area and area.cards then
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if live_game().pattern_row then
					live_game().pattern_row:on_remove_card(card)
				end
				area:remove_card(card)
				if card.bonus_card then
					bonus_return.return_card(card)
				elseif card.boss_temp then
					M.destroy_card(card)
				end
			end
			area:hard_set_cards()
		end
		if live_game().dealt_letters and live_game().dealt_letters.cards then
			for i = #live_game().dealt_letters.cards, 1, -1 do
				local card = live_game().dealt_letters.cards[i]
				live_game().dealt_letters:remove_card(card)
				if card.bonus_card then
					bonus_return.return_card(card)
				elseif card.boss_temp then
					M.destroy_card(card)
				end
			end
		end
	end

	function M.destroy_boss_cards()
		local wr = game_access.word_round()
		local j = wr and wr.jumble
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
		piles.hydrate_hosts_from_store({ "hand", "draw" })
		local cards = {}
		if live_game().dealt_letters and live_game().dealt_letters.cards then
			for _, card in ipairs(live_game().dealt_letters.cards) do
				if core_letter_card.returns_to_draw_pile(card) then
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
				live_game().dealt_letters:remove_card(card)
				live_game().draw_pile:emplace(card)
			end
			M.shuffle_deck()
			commit_piles({ "hand", "draw" })
			if on_complete then on_complete() end
			return
		end
		for i, card in ipairs(cards) do
			if live_game().TIMELINE and live_game().TIMELINE.enqueue then
				Scheduler.add{
					mode = "window",
					delay = (i - 1) * 0.08,
					blocking = true,
					func = function()
						CardMotion.move{from = live_game().dealt_letters, to = live_game().draw_pile, percent = 50, direction = "down", stay_flipped = false, card = card, delay = 0.1}
						return true
					end,
				}
			elseif live_game().dealt_letters and live_game().draw_pile then
				live_game().dealt_letters:remove_card(card)
				live_game().draw_pile:emplace(card)
			end
		end
		if live_game().TIMELINE and live_game().TIMELINE.enqueue then
			Scheduler.add{
				mode = "delayed",
				delay = #cards * 0.08 + 0.25,
				blocking = true,
				func = function()
					M.shuffle_deck()
					commit_piles({ "hand", "draw" })
					if on_complete then on_complete() end
					return true
				end,
			}
		elseif on_complete then
			on_complete()
		end
	end

	M.deal_boss_hand = deal_boss_hand

	function M.recycle_discard_into_deck()
		if not live_game().recycle_stash or not live_game().recycle_stash.cards or #live_game().recycle_stash.cards == 0 then
			return false
		end
		piles.hydrate_hosts_from_store({ "draw", "discard" })
		for i = #live_game().recycle_stash.cards, 1, -1 do
			local card = live_game().recycle_stash.cards[i]
			live_game().recycle_stash:remove_card(card)
			card.played_pool = nil
			card.discard_stash = nil
			if card.states then
				card.states.visible = true
			end
			live_game().draw_pile:emplace(card)
		end
		if live_game().recycle_stash.hard_set_cards then
			live_game().recycle_stash:hard_set_cards()
		end
		M.shuffle_deck()
		commit_piles({ "draw", "discard" })
		return true
	end

	function M.needs_jumble_reshuffle()
		if not M.is_jumble_deck() then return false end
		if M.hand_card_count() > 0 then return false end
		if M.draw_pile_count() > 0 then return false end
		local placement = live_game().pattern_row and live_game().pattern_row.area and live_game().pattern_row.area.cards
		if placement and #placement > 0 then return false end
		local discard_count = (live_game().recycle_stash and live_game().recycle_stash.cards and #live_game().recycle_stash.cards) or 0
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

		piles.hydrate_hosts_from_store({ "draw" })
		local to_deal = math.min(hand_size_cfg.get(), M.draw_pile_count())
		for _ = 1, to_deal do
			local card = live_game().draw_pile:remove_card()
			if card and live_game().dealt_letters then
				live_game().dealt_letters:emplace(card)
			end
		end
		if live_game().dealt_letters then
			live_game().dealt_letters:set_ranks()
			live_game().dealt_letters:relayout()
			live_game().dealt_letters:snap_VT()
			live_game().dealt_letters:hard_set_cards()
		end
		commit_piles({ "hand", "draw", "discard" })
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.ensure_playable_puzzle then
			WORD_GAME.Jumble.ensure_playable_puzzle()
		end
		live_game().ARGS = live_game().ARGS or {}
		live_game().ARGS.pending_layout = true
		if on_complete then on_complete() end
		return true
	end

	function M.deal_jumble_hand()
		if not live_game().dealt_letters then return end
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.clear_blank_cards then
			local wr = game_access.word_round()
			local j = wr and wr.jumble
			if j and j.slots then
				WORD_GAME.Jumble.clear_blank_cards(j.slots)
			end
		end
		voucher_discard.reset()
		M.clear_hand_and_placement()
		piles.hydrate_hosts_from_store({ "draw" })
		local to_deal = math.min(hand_size_cfg.get(), M.draw_pile_count())
		for _ = 1, to_deal do
			local card = live_game().draw_pile:remove_card()
			if card then
				live_game().dealt_letters:emplace(card)
			end
		end
		live_game().dealt_letters:set_ranks()
		live_game().dealt_letters:relayout()
		live_game().dealt_letters:snap_VT()
		live_game().dealt_letters:hard_set_cards()
		commit_piles({ "hand", "draw", "pattern" })
		if WORD_GAME and WORD_GAME.Jumble then
			WORD_GAME.Jumble.ensure_playable_puzzle()
		end
	end

	function M.draw_jumble_replacement()
		if not live_game().dealt_letters then return nil end
		if M.draw_pile_count() == 0 then
			if M.try_jumble_reshuffle_and_deal() then
				local hand = TableAreas.hand_cards()
				return hand[#hand]
			end
			return nil
		end
		piles.hydrate_hosts_from_store({ "draw" })
		local card = live_game().draw_pile:remove_card()
		if not card then return nil end
		local function finish()
			if live_game().dealt_letters then
				live_game().dealt_letters:set_ranks()
				live_game().dealt_letters:relayout()
			end
			commit_piles({ "hand", "draw" })
		end
		if live_game().TIMELINE and live_game().TIMELINE.enqueue then
			Scheduler.add{
				mode = "window",
				delay = 0.05,
				blocking = true,
				func = function()
					CardMotion.move{
						from = live_game().draw_pile,
						to = live_game().dealt_letters,
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
			live_game().dealt_letters:emplace(card)
			finish()
		end
		return card
	end

	function M.discard_from_hand(card)
		if not M.is_jumble_deck() then return false end
		if not voucher_discard.can_discard_card(card) then
			return false
		end

		local function after_discard()
			voucher_discard.stash_discarded_card(card)
			M.draw_jumble_replacement()
			M.sync_deck_count_display()
			if live_game().dealt_letters then
				live_game().dealt_letters:hard_set_cards()
			end
			if live_game().recycle_stash then
				live_game().recycle_stash:relayout()
				live_game().recycle_stash:hard_set_cards()
			end
			Presentation.emit("hand_shuffle_sync")
			game_access.mutate(function(g)
				if g.round_scores then
					g.round_scores.cards_discarded = g.round_scores.cards_discarded or { amt = 0 }
					g.round_scores.cards_discarded.amt = (g.round_scores.cards_discarded.amt or 0) + 1
				end
			end)
		end

		voucher_discard.record_discard()
		local allowance_full = voucher_discard.is_full()
		if allowance_full and card and card.states then
			card.states.visible = false
		end

		local dissolve_time = 0.7
		local function run_dissolve_discard()
			if live_game().dealt_letters then
				live_game().dealt_letters:remove_card(card)
			end
			local vx, vy = voucher_discard and voucher_discard.voucher_discard_center and voucher_discard.voucher_discard_center()
			if vx and vy and card.T then
				local cx = vx - card.T.w * 0.5
				local cy = vy - card.T.h * 0.5
				card.T.x = cx
				card.T.y = cy
				if card.hard_set_T then
					card:hard_set_T(cx, cy, card.T.w, card.T.h)
				end
				if card.snap_VT then card:snap_VT() end
			end
			if card.states then
				card.states.visible = true
			end
			if card.start_dissolve then
				card:start_dissolve(nil, false, 1, true)
			end
			if live_game().TIMELINE and live_game().TIMELINE.enqueue then
				Scheduler.add{
					mode = "delayed",
					delay = dissolve_time,
					blocking = true,
					func = function()
						after_discard()
						return true
					end,
				}
			else
				after_discard()
			end
		end

		if live_game().TIMELINE and live_game().TIMELINE.enqueue then
			run_dissolve_discard()
		elseif live_game().dealt_letters then
			run_dissolve_discard()
		else
			return false
		end

		return true
	end

	function M.refill_jumble_held(target_size)
		target_size = target_size or hand_size_cfg.get()
		while M.held_count() < target_size do
			if not M.draw_jumble_replacement() then break end
		end
		if live_game().dealt_letters then
			live_game().dealt_letters:set_ranks()
			live_game().dealt_letters:relayout()
		end
		LayoutRequest.refresh()
	end
end
