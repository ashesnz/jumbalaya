--[[
	word_game/model/cards/deck/jumble_discard.lua - Voucher discard from hand with dissolve and hand refill

	Core: none
	Store: game_access.dispatch(RECORD_CARD_DISCARDED)
	Presentation: hand_shuffle_sync
]]

local live_game = require("word_game.model.live_game")
local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local hand_size_cfg = require("word_game.model.hand_size")
local voucher_discard = require("word_game.model.perks.voucher_discard")
local Presentation = require("word_game.model.presentation")
local game_access = require("word_game.model.game_access")
local LayoutRequest = require("word_game.model.layout.request")

return function(context)
	local M = context.module

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
			game_access.dispatch({ type = "RECORD_CARD_DISCARDED" })
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
