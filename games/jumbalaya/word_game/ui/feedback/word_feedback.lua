--[[
	word_game/ui/word_feedback.lua - Ephemeral board attention text (gameplay layer).

	Callers:
	  model/feedback.lua  — queue messages from rules (drained each frame)
	  word_feedback       — immediate placement/hand-gap messages during play
	  spawn_attention     — low-level UIBox primitive (exported as global for tests)
	  play_effects        — play cinematics; delegates word messages here
	  float_up_text       — per-card +points / +mult popups (not full sentences)
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local ComicBurst = require("word_game.ui.feedback.comic_burst")
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")

local RunMode = facade.run_mode()

local UIViewHost = require("jumbalaya-engine.panels.view_host")

local M = {}

local INVALID_WORD_TEXT = "Not a valid word!"

function M.spawn_attention(args)
	args = args or {}
	args.text = args.text or 'test'
	args.scale = args.scale or 1
	args.colour = deep_clone(args.colour or runtime().C.WHITE)
	args.hold = (args.hold or 0) + 0.1 * ((runtime() and runtime().TIME_SCALE) or 1)
	args.pos = args.pos or { x = 0, y = 0 }
	args.align = args.align or 'cm'
	args.emboss = args.emboss or nil

	args.fade = 1

	if args.cover then
		args.cover_colour = deep_clone(args.cover_colour or runtime().C.RED)
		args.cover_colour_l = deep_clone(tint(args.cover_colour, 0.2))
		args.cover_colour_d = deep_clone(shade(args.cover_colour, 0.2))
	else
		args.cover_colour = deep_clone(runtime().C.CLEAR)
	end

	args.uibox_config = {
		align = args.align or 'cm',
		offset = args.offset or { x = 0, y = 0 },
		major = args.cover or args.major or nil,
	}

	Scheduler.add{
		mode = 'delayed',
		delay = 0,
		blockable = false,
		blocking = false,
		func = function()
			args.AT = UIViewHost.create{
				T = { args.pos.x, args.pos.y, 0, 0 },
				definition =
					{ n = runtime().UI.ROOT, config = { align = args.cover_align or 'cm', minw = (args.cover and args.cover.T.w or 0.001) + (args.cover_padding or 0), minh = (args.cover and args.cover.T.h or 0.001) + (args.cover_padding or 0), padding = 0.03, r = 0.1, emboss = args.emboss, colour = args.cover_colour }, nodes = {
						{ n = runtime().UI.OBJECT, config = { draw_layer = 1, object = FlowText({ scale = args.scale, string = args.text, maxw = args.maxw, colours = { args.colour }, float = not args.bump, shadow = true, silent = not args.noisy, args.scale, pop_in = 0, pop_in_rate = 6, rotate = args.rotate or nil, bump = args.bump, bump_rate = args.bump_rate, bump_amount = args.bump_amount }) } },
					} },
				config = args.uibox_config
			}
			args.AT.spawn_attention = true

			args.text = args.AT.root_node.children[1].config.object
			args.text:pulse(args.pulse_amount or 0.5)

			if args.cover then
				Particles(args.pos.x, args.pos.y, 0, 0, {
					timer_type = 'TOTAL',
					timer = 0.01,
					pulse_max = 15,
					max = 0,
					scale = 0.3,
					vel_variation = 0.2,
					padding = 0.1,
					fill = true,
					lifespan = 0.5,
					speed = 2.5,
					attach = args.AT.root_node,
					colours = { args.cover_colour, args.cover_colour_l, args.cover_colour_d },
				})
			end
			if args.comic_burst then
				args.burst = ComicBurst(args.pos.x, args.pos.y, 0, 0, {
					attach = args.AT,
					radius = args.burst_radius or 0.62,
				})
			elseif args.backdrop_colour then
				args.backdrop_colour = deep_clone(args.backdrop_colour)
				Particles(args.pos.x, args.pos.y, 0, 0, {
					timer_type = 'TOTAL',
					timer = 5,
					scale = 2.4 * (args.backdrop_scale or 1),
					lifespan = 5,
					speed = 0,
					attach = args.AT,
					colours = { args.backdrop_colour }
				})
			end
			return true
		end
	}

	Scheduler.add{
		mode = 'delayed',
		delay = args.hold,
		blockable = false,
		blocking = false,
		func = function()
			if not args.start_time then
				args.start_time = runtime().TIMERS.TOTAL
				args.text:pop_out(3)
			else
				args.fade = math.max(0, 1 - 3 * (runtime().TIMERS.TOTAL - args.start_time))
				if args.cover_colour then args.cover_colour[4] = math.min(args.cover_colour[4], 2 * args.fade) end
				if args.cover_colour_l then args.cover_colour_l[4] = math.min(args.cover_colour_l[4], args.fade) end
				if args.cover_colour_d then args.cover_colour_d[4] = math.min(args.cover_colour_d[4], args.fade) end
				if args.backdrop_colour then args.backdrop_colour[4] = math.min(args.backdrop_colour[4], args.fade) end
				if args.burst then args.burst.alpha = args.fade end
				args.colour[4] = math.min(args.colour[4], args.fade)
				if args.fade <= 0 then
					args.AT:remove()
					return true
				end
			end
		end
	}
end

local function placement_area()
	return runtime().pattern_row and runtime().pattern_row.area
end

local function hand_dealt_metrics()
	if not runtime().dealt_letters then return nil end

	local wr = game_access.word_round()
	local locked = wr and wr.jumble and wr.jumble.locked_hand_layout
	local left, right, top, bottom

	if locked then
		left = locked.x
		right = locked.x + locked.w
		top = locked.y
		bottom = locked.y + locked.h
	elseif runtime().dealt_letters.cards and #runtime().dealt_letters.cards > 0 then
		for _, card in ipairs(runtime().dealt_letters.cards) do
			if card and card.T then
				local cl = card.T.x
				local cr = card.T.x + (card.T.w or runtime().CARD_W or 1)
				local ct = card.T.y
				local cb = card.T.y + (card.T.h or runtime().CARD_H or 1.4)
				left = left and math.min(left, cl) or cl
				right = right and math.max(right, cr) or cr
				top = top and math.min(top, ct) or ct
				bottom = bottom and math.max(bottom, cb) or cb
			end
		end
	end

	if not left then
		if not runtime().dealt_letters.T then return nil end
		left = runtime().dealt_letters.T.x
		right = runtime().dealt_letters.T.x + runtime().dealt_letters.T.w
		top = runtime().dealt_letters.T.y
		bottom = runtime().dealt_letters.T.y + runtime().dealt_letters.T.h
	end

	local row_w = right - left
	local row_h = bottom - top
	local felt = get_table_felt_rect()
	return {
		cx = left + row_w * 0.5,
		cy = top + row_h * 0.5,
		left = left,
		top = top,
		w = row_w,
		h = row_h,
		bottom = bottom,
		gap_w = math.min(math.max(row_w, runtime().dealt_letters.T.w), felt.w * 0.82),
		inner_h = math.max(row_h, runtime().dealt_letters.T.h),
	}
end

local function hand_gap_metrics()
	local area = placement_area()
	if not area or not area.T or not runtime().dealt_letters or not runtime().dealt_letters.T then return nil end
	local felt = get_table_felt_rect()
	local top = area.T.y + area.T.h
	local bottom = runtime().dealt_letters.T.y
	if bottom <= top + 0.04 then
		bottom = top + math.max(0.28, (runtime().CARD_H or 1) * 0.32)
	end
	local gap = bottom - top
	local pad = math.max(0.08, gap * 0.22)
	local inner_h = math.max(0.12, gap - pad * 2)
	return {
		cx = felt.x + felt.w * 0.5,
		cy = top + pad + inner_h * 0.5,
		gap_w = math.min(area.T.w, felt.w * 0.82),
		inner_h = inner_h,
	}
end

function M.show(text, colour, hold, offset_y)
	local gap = hand_gap_metrics()
	if not gap then
		if spawn_attention then
			spawn_attention({ text = text, scale = 0.5, hold = hold or 1.5,
				align = "cm", colour = colour or runtime().C.RED })
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
		major = runtime().ROOM_ATTACH,
		offset = {
			x = gap.cx - runtime().TILE_W * 0.5,
			y = gap.cy - runtime().TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or runtime().C.RED,
	})
end

function M.show_hand_centered(text, colour, hold, offset_y)
	local row = hand_dealt_metrics()
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
		major = runtime().ROOM_ATTACH,
		offset = {
			x = row.cx - runtime().TILE_W * 0.5,
			y = row.cy - runtime().TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or runtime().C.RED,
	})
end

function M.show_screen_centered(text, colour, hold, offset_y)
	if not spawn_attention then return end
	local scale = math.min(0.82, math.max(0.48, (runtime().TILE_H or 11) * 0.055))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = (runtime().TILE_W or 20) * 0.72,
		hold = hold or 1.2,
		align = "cm",
		major = runtime().ROOM_ATTACH,
		offset = {
			x = 0,
			y = offset_y or 0,
		},
		colour = colour or runtime().C.GOLD,
	})
end

--- Large throbbing 3-2-1 digits, centered on the felt.
function M.show_boss_countdown(text, hold)
	if not spawn_attention then return end
	spawn_attention({
		text = text,
		scale = 2.6,
		hold = hold or 0.85,
		align = "cm",
		major = runtime().ROOM_ATTACH,
		offset = { x = 0, y = 0 },
		colour = runtime().C.GOLD,
		bump = true,
		bump_rate = 2.2,
		bump_amount = 2.4,
		pulse_amount = 0.9,
		noisy = true,
	})
end

function M.show_above_hand_centered(text, colour, hold, offset_y)
	local row = hand_dealt_metrics()
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
		major = runtime().ROOM_ATTACH,
		offset = {
			x = row.cx - runtime().TILE_W * 0.5,
			y = cy - runtime().TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or runtime().C.RED,
	})
end

function M.show_classic_proceed(opts)
	opts = opts or {}
	M.show(RunMode.classic_proceed_message(), runtime().C.RED, opts.hold or 2.8, opts.offset_y or 0.15)
	local major = (runtime().pattern_row and runtime().pattern_row.area)
		or runtime().PLAY_ATTACH
		or runtime().ROOM_ATTACH
	if major and major.pulse then
		major:pulse(0.35, 0.2)
	end
end

function M.show_invalid()
	M.show(INVALID_WORD_TEXT, runtime().C.RED, 1.6)
end

function M.is_invalid_reason(reason)
	return reason == "Not a valid word" or reason == "Does not match"
end

function M.hand_dealt_metrics()
	return hand_dealt_metrics()
end

function M.lock_hand_layout(wr)
	if not wr or not wr.jumble then return end
	wr.jumble.locked_hand_layout = nil
	local metrics = hand_dealt_metrics()
	if not metrics then return end
	wr.jumble.locked_hand_layout = {
		x = metrics.left,
		y = metrics.top,
		w = metrics.w,
		h = metrics.h,
	}
end

function M.flush_pending()
	local pending = runtime().ARGS and runtime().ARGS.word_feedback_queue
	if not pending or #pending == 0 then return end
	runtime().ARGS.word_feedback_queue = nil
	for _, item in ipairs(pending) do
		M.show(item.text, item.colour, item.hold, item.offset_y)
	end
end

spawn_attention = M.spawn_attention

return M