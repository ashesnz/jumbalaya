--[[
	word_game/model/cards/deck/jumble_discard.lua - Discard-bin discard from hand with dissolve and hand refill

	Core: none
	Store: game_access.dispatch(RECORD_CARD_DISCARDED)
	Presentation: hand_shuffle_sync
]]

local live_game = require("word_game.model.live_game")
local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local discard_bin = require("word_game.model.perks.discard_bin")
local Presentation = require("word_game.model.presentation")
local game_access = require("word_game.model.game_access")

local M = {}
local Shared = require("word_game.model.cards.deck.shared")
local function Deck()
	return package.loaded["word_game.model.cards.deck"]
end



	function M.discard_from_hand(card)
		if not Deck().is_jumble_deck() then return false end
		if not discard_bin.can_discard_card(card) then
			return false
		end

		local function after_discard()
			discard_bin.stash_discarded_card(card)
			Deck().commit_pile_hosts({ "hand", "draw", "discard" })
			if Deck().hand_card_count() == 0 then
				Deck().refill_jumble_hand_when_empty()
			else
				Deck().draw_jumble_replacement()
			end
			Deck().sync_deck_count_display()
			if live_game().dealt_letters then
				live_game().dealt_letters:hard_set_cards()
			end
			if live_game().recycle_stash then
				live_game().recycle_stash:relayout()
				live_game().recycle_stash:hard_set_cards()
			end
			Presentation.emit("hand_shuffle_sync")
			game_access.dispatch({ type = "RECORD_CARD_DISCARDED" })
		end

		discard_bin.record_discard()
		local allowance_full = discard_bin.is_full()
		if allowance_full and card and card.states then
			card.states.visible = false
		end

		local dissolve_time = 0.7
		local function run_dissolve_discard()
			if live_game().dealt_letters then
				live_game().dealt_letters:remove_card(card)
			end
			local vx, vy = discard_bin.discard_bin_center and discard_bin.discard_bin_center()
			if vx and vy and card.T then
				local cx = vx - card.T.w * 0.5
				local cy = vy - card.T.h * 0.5
				card.T.x = cx
				card.T.y = cy
				if card.snap_rect then
					card:snap_rect(cx, cy, card.T.w, card.T.h)
				end
				if card.snap_drawn then card:snap_drawn() end
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
return M
