--[[
	word_game/ui/layout/backgrounds.lua - match background staging.

	Owns game().SPLASH_BACK (the full-table backdrop sprite) and its two looks:
	the animated swirl (default) and the garden variant used for the opening
	stages. Also drives the swirl's spin easing through a self-rescheduling
	scheduler event and eases the felt colour per stage.
]]

local game = require("word_game.ui.util.game_runtime").game

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local Easing = require("word_game.ui.effects.easing")

local M = {}

local GARDEN_STAGE_MOSS = {0.38, 0.52, 0.36, 1}

local function remove_current()
	if game().SPLASH_BACK then
		game().SPLASH_BACK:remove()
		game().SPLASH_BACK = nil
	end
end

--- One long-lived event easing the swirl spin amount each tick.
local function ensure_spin_event()
	game().ARGS.spin = game().ARGS.spin or {amount = 0, real = 0, eased = 0}
	game().ARGS.run_bg = game().ARGS.run_bg or {mode = "swirl"}
	if game().ARGS.run_bg.spin_event then return end
	game().ARGS.run_bg.spin_event = true
	Scheduler.add{
		mode = "instant",
		blocking = false,
		blockable = false,
		func = function()
			if not game().ARGS.run_bg or game().ARGS.run_bg.mode ~= "swirl" then
				return false -- done once another look takes over
			end
			local r_dt = game().real_dt or 0.016
			local step = game().ARGS.spin.amount > game().ARGS.spin.eased and r_dt * 2 or 0.3 * r_dt
			local delta = game().ARGS.spin.real - game().ARGS.spin.eased
			if math.abs(delta) > step then delta = delta * step / math.abs(delta) end
			game().ARGS.spin.eased = game().ARGS.spin.eased + delta
			game().ARGS.spin.amount = step * game().ARGS.spin.eased + (1 - step) * game().ARGS.spin.amount
			if game().TIMERS and game().TIMERS.BACKGROUND then
				game().TIMERS.BACKGROUND = game().TIMERS.BACKGROUND - 60 * (game().ARGS.spin.eased - game().ARGS.spin.amount) * step
			end
			return false
		end,
	}
end

function M.garden()
	remove_current()
	game().ARGS.run_bg = game().ARGS.run_bg or {}
	game().ARGS.run_bg.mode = "garden"
	if game().ARGS.spin then
		game().ARGS.spin.amount, game().ARGS.spin.real, game().ARGS.spin.eased = 0, 0, 0
	end

	local atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES["ui_1"]
	if not atlas then
		M.swirl()
		return
	end

	game().SPLASH_BACK = Sprite(-30, -6, game().ROOM.T.w + 60, game().ROOM.T.h + 12, atlas, {x = 2, y = 0})
	game().SPLASH_BACK:set_alignment({
		major = game().ROOM_ATTACH,
		type = "cm",
		offset = {x = 0, y = 0},
	})
	if game().SPLASH_BACK.align_to_major then
		game().SPLASH_BACK:align_to_major()
	end
	game().SPLASH_BACK:define_draw_steps({{
		shader = "garden_leaves",
		send = {
			{name = "time", ref_table = game().TIMERS, ref_value = "REAL"},
		},
	}})

	Easing.background_colour{new_colour = GARDEN_STAGE_MOSS, contrast = 1}
end

function M.swirl()
	remove_current()
	game().ARGS.run_bg = game().ARGS.run_bg or {}
	game().ARGS.run_bg.mode = "swirl"
	ensure_spin_event()

	game().SPLASH_BACK = Sprite(-30, -6, game().ROOM.T.w + 60, game().ROOM.T.h + 12, game().TEXTURE_ATLASES["ui_1"], {x = 2, y = 0})
	game().SPLASH_BACK:set_alignment({
		major = game().ROOM_ATTACH,
		type = "cm",
		bond = "Strong",
		offset = {x = 0, y = 0},
	})
	if game().SPLASH_BACK.align_to_major then
		game().SPLASH_BACK:align_to_major()
	end

	game().SPLASH_BACK:define_draw_steps({{
		shader = "background",
		send = {
			{name = "time", ref_table = game().TIMERS, ref_value = "REAL"},
			{name = "spin_time", ref_table = game().TIMERS, ref_value = "BACKGROUND"},
			{name = "colour_1", ref_table = game().C.BACKGROUND, ref_value = "C"},
			{name = "colour_2", ref_table = game().C.BACKGROUND, ref_value = "L"},
			{name = "colour_3", ref_table = game().C.BACKGROUND, ref_value = "D"},
			{name = "contrast", ref_table = game().C.BACKGROUND, ref_value = "contrast"},
			{name = "spin_amount", ref_table = game().ARGS.spin, ref_value = "amount"},
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
