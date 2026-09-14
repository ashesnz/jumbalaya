--[[ word_game/ui/score_banner/jumble/rolls.lua - Score rolls and breakdown sync ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local Roll = require("jumbalaya-engine.util.roll")
local config = require("word_game.ui.score_banner.jumble.config")
local effects = require("word_game.ui.score_banner.jumble.effects")

local M = {}

function M.apply_score_breakdown(state, breakdown, animate, remain_dur)
	if not breakdown then return end
	local new_earned = breakdown.earned or 0
	local new_got = breakdown.got or 0
	local new_rem = breakdown.remaining or 0

	state.points_earned = new_earned

	local old_got = state.points_got or 0
	if animate and old_got ~= new_got and not state.got_roll then
		M.roll_got_preview(state, old_got, new_got, 0.18)
	else
		state.points_got = new_got
		state.got_roll = nil
	end

	local old_rem = state.points_to_get or new_rem
	if animate and old_rem ~= new_rem and not state.to_get_roll then
		M.roll_points_to_get(state, old_rem, new_rem, remain_dur or 0.18)
	else
		state.points_to_get = new_rem
		state.to_get_roll = nil
	end
end

function M.sync_points_to_get_preview(state, animate, opts)
	if state.hide_points_to_get then return end
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	local rules = facade.jumble_rules()
	local target = (wr and wr.target) or rules.round_target()
	M.apply_score_breakdown(state, rules.score_breakdown(j, target), animate, opts and opts.remain_dur)
end

function M.roll_got_preview(state, from_val, to_val, dur)
	from_val = from_val or state.points_got or 0
	to_val = to_val or from_val
	dur = dur or config.TO_GET_ROLL_TIME
	local roll = Roll.begin(from_val, to_val, dur, { integer = true })
	state.got_roll = roll
	if not roll then
		state.points_got = to_val
	end
end

function M.roll_points_to_get(state, from_val, to_val, dur)
	from_val = from_val or state.points_to_get or 20
	to_val = to_val or from_val
	dur = dur or config.TO_GET_ROLL_TIME
	local roll = Roll.begin(from_val, to_val, dur, { integer = true })
	state.to_get_roll = roll
	if not roll then
		state.points_to_get = to_val
	end
end

function M.roll_jumble_score(state, from_pts, to_pts, from_multi, to_multi)
	from_pts = from_pts or state.jumble_points or 0
	to_pts = to_pts or from_pts
	from_multi = from_multi or state.jumble_multi or 1.0
	to_multi = to_multi or from_multi

	local changed = false

	local points_roll = Roll.begin(from_pts, to_pts, config.ROLL_TIME)
	if points_roll then
		state.points_roll = points_roll
		effects.trigger_points_bounce(state, 1.0)
		effects.trigger_points_spin(state)
		changed = true
	else
		state.jumble_points = to_pts
		state.points_roll = nil
	end

	local multi_roll = Roll.begin(from_multi, to_multi, config.ROLL_TIME)
	if multi_roll then
		state.multi_roll = multi_roll
		effects.trigger_multi_bounce(state, 1.0)
		effects.trigger_multi_spin(state)
		changed = true
	else
		state.jumble_multi = to_multi
		state.multi_roll = nil
	end

	if changed then
		state.pulse_togo()
		if play_sfx then play_sfx("card_tick", 0.75, 0.5) end
	end
end

return M
