--[[
	word_game/ui/layout/backgrounds.lua - match background staging.

	Owns G.SPLASH_BACK (the full-table backdrop sprite) and its two looks:
	the animated swirl (default) and the garden variant used for the opening
	stages. Also drives the swirl's spin easing through a self-rescheduling
	scheduler event and eases the felt colour per stage.
]]

local Scheduler = require "app.effects.timeline_scheduler"

local M = {}

local GARDEN_STAGE_MOSS = {0.38, 0.52, 0.36, 1}

-- Garden (falling leaves) board for all stages.
function M.is_garden_stage(set, hand_index)
	return true
end

local function remove_current()
	if G.SPLASH_BACK then
		G.SPLASH_BACK:remove()
		G.SPLASH_BACK = nil
	end
end

--- One long-lived event easing the swirl spin amount each tick.
local function ensure_spin_event()
	G.ARGS.spin = G.ARGS.spin or {amount = 0, real = 0, eased = 0}
	G.ARGS.run_bg = G.ARGS.run_bg or {mode = "swirl"}
	if G.ARGS.run_bg.spin_event then return end
	G.ARGS.run_bg.spin_event = true
	Scheduler.add{
		mode = "instant",
		blocking = false,
		blockable = false,
		func = function()
			if not G.ARGS.run_bg or G.ARGS.run_bg.mode ~= "swirl" then
				return false -- done once another look takes over
			end
			local r_dt = G.real_dt or 0.016
			local step = G.ARGS.spin.amount > G.ARGS.spin.eased and r_dt * 2 or 0.3 * r_dt
			local delta = G.ARGS.spin.real - G.ARGS.spin.eased
			if math.abs(delta) > step then delta = delta * step / math.abs(delta) end
			G.ARGS.spin.eased = G.ARGS.spin.eased + delta
			G.ARGS.spin.amount = step * G.ARGS.spin.eased + (1 - step) * G.ARGS.spin.amount
			if G.TIMERS and G.TIMERS.BACKGROUND then
				G.TIMERS.BACKGROUND = G.TIMERS.BACKGROUND - 60 * (G.ARGS.spin.eased - G.ARGS.spin.amount) * step
			end
			return false
		end,
	}
end

function M.garden()
	remove_current()
	G.ARGS.run_bg = G.ARGS.run_bg or {}
	G.ARGS.run_bg.mode = "garden"
	if G.ARGS.spin then
		G.ARGS.spin.amount, G.ARGS.spin.real, G.ARGS.spin.eased = 0, 0, 0
	end

	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES["ui_1"]
	if not atlas then
		M.swirl()
		return
	end

	G.SPLASH_BACK = Sprite(-30, -6, G.ROOM.T.w + 60, G.ROOM.T.h + 12, atlas, {x = 2, y = 0})
	G.SPLASH_BACK:set_alignment({
		major = G.ROOM_ATTACH,
		type = "cm",
		offset = {x = 0, y = 0},
	})
	G.SPLASH_BACK:define_draw_steps({{
		shader = "garden_leaves",
		send = {
			{name = "time", ref_table = G.TIMERS, ref_value = "REAL"},
		},
	}})

	if ease_background_colour then
		ease_background_colour{new_colour = GARDEN_STAGE_MOSS, contrast = 1}
	end
end

function M.swirl()
	remove_current()
	G.ARGS.run_bg = G.ARGS.run_bg or {}
	G.ARGS.run_bg.mode = "swirl"
	ensure_spin_event()

	G.SPLASH_BACK = Sprite(-30, -6, G.ROOM.T.w + 60, G.ROOM.T.h + 12, G.TEXTURE_ATLASES["ui_1"], {x = 2, y = 0})
	G.SPLASH_BACK:set_alignment({
		major = G.hand,
		type = "cm",
		bond = "Strong",
		offset = {x = 0, y = 0},
	})

	G.SPLASH_BACK:define_draw_steps({{
		shader = "background",
		send = {
			{name = "time", ref_table = G.TIMERS, ref_value = "REAL"},
			{name = "spin_time", ref_table = G.TIMERS, ref_value = "BACKGROUND"},
			{name = "colour_1", ref_table = G.C.BACKGROUND, ref_value = "C"},
			{name = "colour_2", ref_table = G.C.BACKGROUND, ref_value = "L"},
			{name = "colour_3", ref_table = G.C.BACKGROUND, ref_value = "D"},
			{name = "contrast", ref_table = G.C.BACKGROUND, ref_value = "contrast"},
			{name = "spin_amount", ref_table = G.ARGS.spin, ref_value = "amount"},
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
