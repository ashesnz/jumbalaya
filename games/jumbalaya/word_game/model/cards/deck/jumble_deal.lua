--[[
	word_game/model/cards/deck/jumble_deal.lua - Jumble return-to-deck, recycle, reshuffle, deal, draw replacement

	Core: jumbalaya_core.cards.letter_card
	Store: piles via context.commit_piles
	Presentation: card_motion_move
]]

local live_game = require("word_game.model.live_game")

local function jumble()
	return package.loaded["word_game.model.jumble"]
end
local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local card_motion_request = require("word_game.model.card_motion_request")
local hand_size_cfg = require("word_game.model.hand_size")
local game_access = require("word_game.model.game_access")
local piles = require("word_game.model.piles")
local TableAreas = require("word_game.model.table_areas")
local core_letter_card = require("jumbalaya_core.cards.letter_card")
local voucher_discard = require("word_game.model.perks.voucher_discard")

return function(context)
	local M = context.module

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
			context.commit_piles({ "hand", "draw" })
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
						card_motion_request.move{from = live_game().dealt_letters, to = live_game().draw_pile, percent = 50, direction = "down", stay_flipped = false, card = card, delay = 0.1}
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
					context.commit_piles({ "hand", "draw" })
					if on_complete then on_complete() end
					return true
				end,
			}
		elseif on_complete then
			on_complete()
		end
	end

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
		context.commit_piles({ "draw", "discard" })
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
		context.commit_piles({ "hand", "draw", "discard" })
		local j = jumble()
		if j and j.ensure_playable_puzzle then j.ensure_playable_puzzle() end
		live_game().ARGS = live_game().ARGS or {}
		live_game().ARGS.pending_layout = true
		if on_complete then on_complete() end
		return true
	end

	function M.deal_jumble_hand()
		if not live_game().dealt_letters then return end
		local jumble_api = jumble()
		if jumble_api and jumble_api.clear_blank_cards then
			local wr = game_access.word_round()
			local j = wr and wr.jumble
			if j and j.slots then
				jumble_api.clear_blank_cards(j.slots)
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
		context.commit_piles({ "hand", "draw", "pattern" })
		local j = jumble()
		if j and j.ensure_playable_puzzle then j.ensure_playable_puzzle() end
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
			context.commit_piles({ "hand", "draw" })
		end
		if live_game().TIMELINE and live_game().TIMELINE.enqueue then
			Scheduler.add{
				mode = "window",
				delay = 0.05,
				blocking = true,
				func = function()
					card_motion_request.move{
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
end
