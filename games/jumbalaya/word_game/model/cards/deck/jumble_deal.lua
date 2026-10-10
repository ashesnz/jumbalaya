--[[
	word_game/model/cards/deck/jumble_deal.lua - Jumble return-to-deck, recycle, reshuffle, deal, draw replacement

	Core: jumbalaya_core.cards.letter_card
	Store: piles via context.commit_piles
	Presentation: card_motion_move; layout via LayoutRequest.refresh()
]]

local live_game = require("word_game.model.live_game")

local function jumble()
	return package.loaded["word_game.model.jumble"]
end
local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local LayoutRequest = require("word_game.model.layout.request")
local card_motion_request = require("word_game.model.card_motion_request")
local hand_size_cfg = require("word_game.model.hand_size")
local game_access = require("word_game.model.game_access")
local piles = require("word_game.model.piles")
local TableAreas = require("word_game.model.table_areas")
local core_letter_card = require("jumbalaya_core.cards.letter_card")
local discard_bin = require("word_game.model.perks.discard_bin")

local M = {}
local Shared = require("word_game.model.cards.deck.shared")
local function Deck()
	return package.loaded["word_game.model.cards.deck"]
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
				piles.present_card(card, "draw", { from_pile = "hand" })
			end
			Deck().shuffle_deck()
			Shared.commit_piles({ "hand", "draw" })
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
				piles.present_card(card, "draw", { from_pile = "hand" })
			end
		end
		if live_game().TIMELINE and live_game().TIMELINE.enqueue then
			Scheduler.add{
				mode = "delayed",
				delay = #cards * 0.08 + 0.25,
				blocking = true,
				func = function()
					Deck().shuffle_deck()
					Shared.commit_piles({ "hand", "draw" })
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
			piles.present_card(card, "draw", { from_pile = "discard" })
		end
		if live_game().recycle_stash.hard_set_cards then
			live_game().recycle_stash:hard_set_cards()
		end
		Deck().shuffle_deck()
		Shared.commit_piles({ "draw", "discard" })
		return true
	end

	local function recycle_stash_count()
		return (live_game().recycle_stash and live_game().recycle_stash.cards and #live_game().recycle_stash.cards) or 0
	end

	local function pattern_empty()
		local placement = live_game().pattern_row and live_game().pattern_row.area and live_game().pattern_row.area.cards
		return not placement or #placement == 0
	end

	function M.ensure_draw_pile_from_recycle()
		if Deck().draw_pile_count() > 0 then return true end
		return Deck().recycle_discard_into_deck()
	end

	--- Hand empty, pattern clear: merge recycle into draw if needed, then deal a full jumble hand.
	function M.refill_jumble_hand_when_empty(on_complete)
		if not Deck().is_jumble_deck() then
			if on_complete then on_complete() end
			return false
		end
		if Deck().hand_card_count() > 0 or not pattern_empty() then
			if on_complete then on_complete() end
			return false
		end
		local target = hand_size_cfg.get()
		if Deck().draw_pile_count() < target and recycle_stash_count() > 0 then
			Deck().recycle_discard_into_deck()
		end
		if Deck().draw_pile_count() <= 0 then
			if on_complete then on_complete() end
			return false
		end
		local dealt = Deck().deal_into_hand(target, function()
			local j = jumble()
			if j and j.ensure_playable_puzzle then j.ensure_playable_puzzle() end
			LayoutRequest.refresh()
			if on_complete then on_complete() end
		end)
		return (dealt or 0) > 0
	end

	function M.needs_jumble_reshuffle()
		if not Deck().is_jumble_deck() then return false end
		if Deck().hand_card_count() > 0 then return false end
		if not pattern_empty() then return false end
		local target = hand_size_cfg.get()
		local in_draw = Deck().draw_pile_count()
		if in_draw >= target then return false end
		return (in_draw + recycle_stash_count()) > 0
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
		discard_bin.reset()
		Deck().clear_hand_and_placement()
		piles.hydrate_hosts_from_store({ "draw" })
		local to_deal = math.min(hand_size_cfg.get(), Deck().draw_pile_count())
		for _ = 1, to_deal do
			local card = live_game().draw_pile:remove_card()
			if card then
				piles.present_card(card, "hand", { from_pile = "draw" })
			end
		end
		live_game().dealt_letters:refresh_order()
		live_game().dealt_letters:relayout()
		live_game().dealt_letters:snap_drawn()
		live_game().dealt_letters:hard_set_cards()
		Shared.commit_piles({ "hand", "draw", "pattern" })
		local j = jumble()
		if j and j.ensure_playable_puzzle then j.ensure_playable_puzzle() end
	end

	function M.draw_jumble_replacement()
		if not live_game().dealt_letters then return nil end
		if Deck().draw_pile_count() == 0 then
			if not Deck().ensure_draw_pile_from_recycle() then
				return nil
			end
		end
		piles.hydrate_hosts_from_store({ "draw" })
		local card = live_game().draw_pile:remove_card()
		if not card then return nil end
		local function finish()
			if live_game().dealt_letters then
				live_game().dealt_letters:refresh_order()
				live_game().dealt_letters:relayout()
			end
			Shared.commit_piles({ "hand", "draw" })
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
		elseif Shared.fly_from_deck_to_hand then
			Shared.fly_from_deck_to_hand(card)
			finish()
		else
			piles.present_card(card, "hand", { from_pile = "draw" })
			finish()
		end
		return card
	end
return M
