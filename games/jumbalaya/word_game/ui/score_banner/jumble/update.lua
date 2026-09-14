--[[ word_game/ui/score_banner/jumble/update.lua - Per-frame score banner animation ]]

local Roll = require("jumbalaya-engine.util.roll")
local ComicBurst = require("word_game.ui.feedback.comic_burst")
local config = require("word_game.ui.score_banner.jumble.config")

local M = {}

local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
function M.update(state, dt)
	dt = dt or (love and love.timer and love.timer.getDelta and math.min(0.05, love.timer.getDelta()) or 0.016)
	if state.points_roll then
		local roll, done = Roll.tick(state.points_roll, dt)
		state.points_roll = roll
		if done then state.jumble_points = done end
	end
	if state.multi_roll then
		local roll, done = Roll.tick(state.multi_roll, dt)
		state.multi_roll = roll
		if done then state.jumble_multi = done end
	end
	if state.points_bounce then
		state.points_bounce.t = state.points_bounce.t + dt
		if state.points_bounce.t >= state.points_bounce.dur then
			state.points_bounce = nil
		end
	end
	if state.multi_bounce then
		state.multi_bounce.t = state.multi_bounce.t + dt
		if state.multi_bounce.t >= state.multi_bounce.dur then
			state.multi_bounce = nil
		end
	end
	if state.points_spin then
		state.points_spin.t = state.points_spin.t + dt
		if state.points_spin.t >= state.points_spin.dur then
			state.points_rot = state.points_spin.target_box
			state.points_spin = nil
		end
	end
	if state.multi_spin then
		state.multi_spin.t = state.multi_spin.t + dt
		if state.multi_spin.t >= state.multi_spin.dur then
			state.multi_rot = state.multi_spin.target_box
			state.multi_spin = nil
		end
	end
	if state.points_burst then
		ComicBurst.advance(state.points_burst, dt)
		if state.points_burst.age > config.BURST_HOLD then
			state.points_burst.alpha = math.max(0, 1 - (state.points_burst.age - config.BURST_HOLD) / config.BURST_FADE)
		end
		if state.points_burst.alpha <= 0 then
			state.points_burst = nil
		end
	end
	if state.multi_burst then
		ComicBurst.advance(state.multi_burst, dt)
		if state.multi_burst.age > config.BURST_HOLD then
			state.multi_burst.alpha = math.max(0, 1 - (state.multi_burst.age - config.BURST_HOLD) / config.BURST_FADE)
		end
		if state.multi_burst.alpha <= 0 then
			state.multi_burst = nil
		end
	end
	if state.to_get_roll then
		local roll, cur = Roll.tick_integer(state.to_get_roll, dt, function()
			if play_sfx then play_sfx("card_tick", 0.7, 0.4) end
		end)
		state.to_get_roll = roll
		if cur ~= nil then state.points_to_get = cur end
	end
	if state.got_roll then
		local roll, cur = Roll.tick_integer(state.got_roll, dt, function()
			if play_sfx then play_sfx("card_tick", 0.65, 0.35) end
		end)
		state.got_roll = roll
		if cur ~= nil then state.points_got = cur end
	end
end

return M
