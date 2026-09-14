--[[
	word_game/ui/feedback/word_feedback.lua — Ephemeral full-sentence board attention text.
]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local shell = facade.shell()
local geometry = require("word_game.ui.feedback.word_feedback_geometry")
local spawn = require("word_game.ui.feedback.word_feedback_spawn")

local RunMode = facade.run_mode()

local M = {}

local INVALID_WORD_TEXT = "Not a valid word!"

function M.spawn_attention(args)
	spawn.spawn_attention(args)
end

function M.show(text, colour, hold, offset_y)
	local gap = geometry.hand_gap_metrics()
	if not gap then
		if spawn_attention then
			spawn_attention({ text = text, scale = 0.5, hold = hold or 1.5,
				align = "cm", colour = colour or game().C.RED })
		end
		return
	end
	if not spawn_attention then return end
	local scale = math.min(0.68, math.max(0.36, gap.inner_h * 1.45))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = gap.gap_w,
		hold = hold or 1.5,
		align = "cm",
		major = game().ROOM_ATTACH,
		offset = {
			x = gap.cx - game().TILE_W * 0.5,
			y = gap.cy - game().TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or game().C.RED,
	})
end

function M.show_hand_centered(text, colour, hold, offset_y)
	local row = geometry.hand_dealt_metrics()
	if not row then
		M.show(text, colour, hold, offset_y)
		return
	end
	if not spawn_attention then return end
	local scale = math.min(0.72, math.max(0.38, row.inner_h * 1.35))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = row.gap_w,
		hold = hold or 1.5,
		align = "cm",
		major = game().ROOM_ATTACH,
		offset = {
			x = row.cx - game().TILE_W * 0.5,
			y = row.cy - game().TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or game().C.RED,
	})
end

function M.show_screen_centered(text, colour, hold, offset_y)
	if not spawn_attention then return end
	local scale = math.min(0.82, math.max(0.48, (game().TILE_H or 11) * 0.055))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = (game().TILE_W or 20) * 0.72,
		hold = hold or 1.2,
		align = "cm",
		major = game().ROOM_ATTACH,
		offset = {
			x = 0,
			y = offset_y or 0,
		},
		colour = colour or game().C.GOLD,
	})
end

function M.show_boss_countdown(text, hold)
	if not spawn_attention then return end
	spawn_attention({
		text = text,
		scale = 2.6,
		hold = hold or 0.85,
		align = "cm",
		major = game().ROOM_ATTACH,
		offset = { x = 0, y = 0 },
		colour = game().C.GOLD,
		bump = true,
		bump_rate = 2.2,
		bump_amount = 2.4,
		pulse_amount = 0.9,
		noisy = true,
	})
end

function M.show_above_hand_centered(text, colour, hold, offset_y)
	local row = geometry.hand_dealt_metrics()
	if not row then
		M.show(text, colour, hold, offset_y)
		return
	end
	if not spawn_attention then return end
	local zone_h = math.max(0.18, row.inner_h * 0.34)
	local margin = math.max(0.06, row.inner_h * 0.08)
	local cy = row.top - margin - zone_h * 0.5
	local scale = math.min(0.78, math.max(0.42, zone_h * 1.55))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = row.gap_w,
		hold = hold or 1.5,
		align = "cm",
		major = game().ROOM_ATTACH,
		offset = {
			x = row.cx - game().TILE_W * 0.5,
			y = cy - game().TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or game().C.RED,
	})
end

function M.show_classic_proceed(opts)
	opts = opts or {}
	M.show(RunMode.classic_proceed_message(), game().C.RED, opts.hold or 2.8, opts.offset_y or 0.15)
	local row = shell.pattern_row()
	local major = (row and row.area) or game().PLAY_ATTACH or game().ROOM_ATTACH
	if major and major.pulse then
		major:pulse(0.35, 0.2)
	end
end

function M.show_invalid()
	M.show(INVALID_WORD_TEXT, game().C.RED, 1.6)
end

function M.is_invalid_reason(reason)
	return reason == "Not a valid word" or reason == "Does not match"
end

function M.hand_dealt_metrics()
	return geometry.hand_dealt_metrics()
end

function M.lock_hand_layout(_wr)
	local metrics = geometry.hand_dealt_metrics()
	if not metrics then
		game_access.dispatch({ type = "JUMBLE_SET_LOCKED_HAND_LAYOUT" })
		return
	end
	game_access.dispatch({
		type = "JUMBLE_SET_LOCKED_HAND_LAYOUT",
		layout = {
			x = metrics.left,
			y = metrics.top,
			w = metrics.w,
			h = metrics.h,
		},
	})
end

function M.flush_pending()
	local pending = shell.word_feedback_queue()
	if not pending or #pending == 0 then return end
	shell.clear_word_feedback_queue()
	for _, item in ipairs(pending) do
		M.show(item.text, item.colour, item.hold, item.offset_y)
	end
end

spawn_attention = M.spawn_attention

return M
