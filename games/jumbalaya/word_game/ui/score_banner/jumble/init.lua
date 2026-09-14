--[[ word_game/ui/score_banner/jumble/init.lua - Jumble score state, rolls, and animation ]]

local config = require("word_game.ui.score_banner.jumble.config")
local state = require("word_game.ui.score_banner.jumble.state")
local effects = require("word_game.ui.score_banner.jumble.effects")
local rolls = require("word_game.ui.score_banner.jumble.rolls")
local update_mod = require("word_game.ui.score_banner.jumble.update")

local M = state

for k, v in pairs(config) do
	M[k] = v
end

function M.trigger_points_bounce(amp)
	effects.trigger_points_bounce(M, amp)
end

function M.trigger_multi_bounce(amp)
	effects.trigger_multi_bounce(M, amp)
end

function M.trigger_points_spin()
	effects.trigger_points_spin(M)
end

function M.trigger_multi_spin()
	effects.trigger_multi_spin(M)
end

function M.spawn_points_burst()
	M.points_burst = require("word_game.ui.feedback.comic_burst").make(1)
end

function M.spawn_multi_burst()
	M.multi_burst = require("word_game.ui.feedback.comic_burst").make(1)
end

M.calc_box_rotation = effects.calc_box_rotation
M.calc_digit_rotation = effects.calc_digit_rotation
M.calc_layout = effects.calc_layout
M.calc_bounce = effects.calc_bounce
M.get_multi_growth = effects.get_multi_growth
M.calc_points_to_get_pos = effects.calc_points_to_get_pos

function M.apply_score_breakdown(breakdown, animate, remain_dur)
	rolls.apply_score_breakdown(M, breakdown, animate, remain_dur)
end

function M.sync_points_to_get_preview(animate, opts)
	rolls.sync_points_to_get_preview(M, animate, opts)
end

function M.roll_got_preview(from_val, to_val, dur)
	rolls.roll_got_preview(M, from_val, to_val, dur)
end

function M.roll_points_to_get(from_val, to_val, dur)
	rolls.roll_points_to_get(M, from_val, to_val, dur)
end

function M.roll_jumble_score(from_pts, to_pts, from_multi, to_multi)
	rolls.roll_jumble_score(M, from_pts, to_pts, from_multi, to_multi)
end

local base_reset = M.reset_jumble_score
function M.reset_jumble_score()
	base_reset()
	M.sync_points_to_get_preview(false)
end

function M.update(dt)
	update_mod.update(M, dt)
end

return M
