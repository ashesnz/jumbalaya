--[[
	word_game/ui/layout/backgrounds.lua - match background staging.

	Owns runtime().SPLASH_BACK (the full-table backdrop sprite) and its two looks:
	the animated swirl (default) and the garden variant used for the opening
	stages. Also drives the swirl's spin easing through a self-rescheduling
	scheduler event and eases the felt colour per stage.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"

local M = {}

local GARDEN_STAGE_MOSS = {0.38, 0.52, 0.36, 1}

local function remove_current()
	if runtime().SPLASH_BACK then
		runtime().SPLASH_BACK:remove()
		runtime().SPLASH_BACK = nil
	end
end

--- One long-lived event easing the swirl spin amount each tick.
local function ensure_spin_event()
	runtime().ARGS.spin = runtime().ARGS.spin or {amount = 0, real = 0, eased = 0}
	runtime().ARGS.run_bg = runtime().ARGS.run_bg or {mode = "swirl"}
	if runtime().ARGS.run_bg.spin_event then return end
	runtime().ARGS.run_bg.spin_event = true
	Scheduler.add{
		mode = "instant",
		blocking = false,
		blockable = false,
		func = function()
			if not runtime().ARGS.run_bg or runtime().ARGS.run_bg.mode ~= "swirl" then
				return false -- done once another look takes over
			end
			local r_dt = runtime().real_dt or 0.016
			local step = runtime().ARGS.spin.amount > runtime().ARGS.spin.eased and r_dt * 2 or 0.3 * r_dt
			local delta = runtime().ARGS.spin.real - runtime().ARGS.spin.eased
			if math.abs(delta) > step then delta = delta * step / math.abs(delta) end
			runtime().ARGS.spin.eased = runtime().ARGS.spin.eased + delta
			runtime().ARGS.spin.amount = step * runtime().ARGS.spin.eased + (1 - step) * runtime().ARGS.spin.amount
			if runtime().TIMERS and runtime().TIMERS.BACKGROUND then
				runtime().TIMERS.BACKGROUND = runtime().TIMERS.BACKGROUND - 60 * (runtime().ARGS.spin.eased - runtime().ARGS.spin.amount) * step
			end
			return false
		end,
	}
end

function M.garden()
	remove_current()
	runtime().ARGS.run_bg = runtime().ARGS.run_bg or {}
	runtime().ARGS.run_bg.mode = "garden"
	if runtime().ARGS.spin then
		runtime().ARGS.spin.amount, runtime().ARGS.spin.real, runtime().ARGS.spin.eased = 0, 0, 0
	end

	local atlas = runtime().TEXTURE_ATLASES and runtime().TEXTURE_ATLASES["ui_1"]
	if not atlas then
		M.swirl()
		return
	end

	runtime().SPLASH_BACK = Sprite(-30, -6, runtime().ROOM.T.w + 60, runtime().ROOM.T.h + 12, atlas, {x = 2, y = 0})
	runtime().SPLASH_BACK:set_alignment({
		major = runtime().ROOM_ATTACH,
		type = "cm",
		offset = {x = 0, y = 0},
	})
	runtime().SPLASH_BACK:define_draw_steps({{
		shader = "garden_leaves",
		send = {
			{name = "time", ref_table = runtime().TIMERS, ref_value = "REAL"},
		},
	}})

	if ease_background_colour then
		ease_background_colour{new_colour = GARDEN_STAGE_MOSS, contrast = 1}
	end
end

function M.swirl()
	remove_current()
	runtime().ARGS.run_bg = runtime().ARGS.run_bg or {}
	runtime().ARGS.run_bg.mode = "swirl"
	ensure_spin_event()

	runtime().SPLASH_BACK = Sprite(-30, -6, runtime().ROOM.T.w + 60, runtime().ROOM.T.h + 12, runtime().TEXTURE_ATLASES["ui_1"], {x = 2, y = 0})
	runtime().SPLASH_BACK:set_alignment({
		major = runtime().dealt_letters,
		type = "cm",
		bond = "Strong",
		offset = {x = 0, y = 0},
	})

	runtime().SPLASH_BACK:define_draw_steps({{
		shader = "background",
		send = {
			{name = "time", ref_table = runtime().TIMERS, ref_value = "REAL"},
			{name = "spin_time", ref_table = runtime().TIMERS, ref_value = "BACKGROUND"},
			{name = "colour_1", ref_table = runtime().C.BACKGROUND, ref_value = "C"},
			{name = "colour_2", ref_table = runtime().C.BACKGROUND, ref_value = "L"},
			{name = "colour_3", ref_table = runtime().C.BACKGROUND, ref_value = "D"},
			{name = "contrast", ref_table = runtime().C.BACKGROUND, ref_value = "contrast"},
			{name = "spin_amount", ref_table = runtime().ARGS.spin, ref_value = "amount"},
		},
	}})
end

function M.stage(set, hand_index)
	M.garden()
end

function M.run()
	M.stage(1, 1)
end

return M
