--[[ word_game/ui/table/controls/placement.lua - Play button logic (registered as play_placement_word) ]]

local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local word_feedback = require("word_game.ui.feedback.word_feedback")
local play_resolution = require("word_game.ui.play_effects.resolution")
local play_effects = require("word_game.ui.play_effects")
local round_config = require("jumbalaya_core.config.gameplay.round")

local InputLock = facade.input_lock()
local RunMode = facade.run_mode()
local game_access = facade.game_access()

local M = {}

local function boss_placement_active(j, wr)
	if not j or not wr or not round_config.is_boss_word_hand(wr.set, wr.hand_index) then
		return false
	end
	return j.boss_word_active == true or (j.boss_cards and #j.boss_cards > 0)
end

local function hand_has_dealt_cards()
	local dealt = game().dealt_letters
	if not dealt or not dealt.cards then
		return false
	end
	for _, card in ipairs(dealt.cards) do
		if card and not card.REMOVED then
			return true
		end
	end
	return false
end

--- Boss showdown: when every dealt letter sits on the row, submit automatically (no Play tap).
function M.should_auto_play_boss()
	local Jumble = facade.jumble()
	if not Jumble or not Jumble.is_active() then
		return false
	end
	local wr = game_access.word_round()
	local j = Jumble.state()
	if not boss_placement_active(j, wr) then
		return false
	end
	if hand_has_dealt_cards() then
		return false
	end
	if not j.slots or not j.puzzle then
		return false
	end
	return Jumble.all_blanks_filled(j.slots, j.puzzle)
end

--- If a boss-stage animation died mid-flight, Play can stay locked until the player retries.
local function try_unlock_stuck_boss_play()
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	local g = game_access.get()
	if not (j and j.boss_word_active and g and g.word_score_animating) then
		return false
	end
	if facade.bonus_stack() and facade.bonus_stack().is_animating() then
		return false
	end
	play_effects.set_word_score_animating(false)
	return true
end

function M.try_play()
	if InputLock.is_table_busy() and not try_unlock_stuck_boss_play() then
		return
	end
	if RunMode.classic_stage_complete() then
		local hand_shuffle = WORD_GAME_UI.TableControls
		if not (hand_shuffle and hand_shuffle.placement_has_cards()) then
			word_feedback.show_classic_proceed({ hold = 2.2 })
		else
			play_resolution.resolve(facade.jumble_play())
		end
		return
	end
	local hold_redraw = WORD_GAME_UI.PlayHoldRedraw
	if hold_redraw and hold_redraw.consume_click and hold_redraw.consume_click() then
		return
	end
	play_resolution.resolve(facade.jumble_play())
end

function M.maybe_auto_play_after_placement()
	if not M.should_auto_play_boss() then
		return
	end
	Scheduler.add{
		mode = "delayed",
		delay = 0.05,
		blockable = false,
		blocking = false,
		func = function()
			M.try_play()
			return true
		end,
	}
end

return M
