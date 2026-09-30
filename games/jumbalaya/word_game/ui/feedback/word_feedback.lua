--[[
	word_game/ui/feedback/word_feedback.lua — Ephemeral full-sentence board attention text.
]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local shell = facade.shell()
local geometry = require("word_game.ui.feedback.word_feedback_geometry")
local spawn = require("word_game.ui.feedback.word_feedback_spawn")
local Layout = require("word_game.ui.layout")

local RunMode = facade.run_mode()

local M = {}

local INVALID_WORD_TEXT = "Not a valid word!"
local MUST_PLAY_TEXT = "Word must be played!"
local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local SHADOW = { 0.07, 0.05, 0.08, 0.92 }
local DEFAULT_RED = { 1, 0.18, 0.22, 1 }

local overlay_font
local messages = {}

local function board_font()
	if overlay_font then return overlay_font end
	local ok, font = pcall(love.graphics.newFont, FONT_FILE, 42)
	if not ok or not font then
		font = love.graphics.newFont(42)
	end
	font:setFilter("linear", "linear")
	overlay_font = font
	return font
end

local function fallback_rect(offset_y)
	offset_y = offset_y or 0
	local felt = Layout.felt_rect and Layout.felt_rect()
	if felt then
		return {
			x = felt.x,
			y = felt.y + felt.h * 0.38 + offset_y,
			w = felt.w,
			h = 0.85,
		}
	end
	return {
		x = 1.2,
		y = 4.0 + offset_y,
		w = (game().TILE_W or 20) - 2.4,
		h = 0.85,
	}
end

local function board_message_rect(offset_y)
	offset_y = offset_y or 0
	local gap = geometry.hand_gap_metrics()
	if gap then
		local h = math.max(0.7, gap.inner_h)
		return {
			x = gap.cx - math.max(6, gap.gap_w) * 0.5,
			y = gap.cy - h * 0.5 + offset_y,
			w = math.max(6, gap.gap_w),
			h = h,
		}
	end
	local row = geometry.hand_dealt_metrics()
	if row then
		local h = 0.75
		return {
			x = row.left,
			y = row.top - h - 0.1 + offset_y,
			w = math.max(6, row.w),
			h = h,
		}
	end
	return fallback_rect(offset_y)
end

local function push_message(text, colour, hold, rect)
	if not text or text == "" then return end
	messages[#messages + 1] = {
		text = tostring(text),
		colour = colour or (game().C and game().C.RED) or DEFAULT_RED,
		x = rect.x,
		y = rect.y,
		w = rect.w,
		h = rect.h,
		age = 0,
		life = hold or 1.6,
		alpha = 1,
	}
end

function M.spawn_attention(args)
	spawn.spawn_attention(args)
end

function M.show(text, colour, hold, offset_y)
	push_message(text, colour, hold, board_message_rect(offset_y))
end

function M.show_screen_centered(text, colour, hold, offset_y)
	local scale = math.min(0.82, math.max(0.48, (game().TILE_H or 11) * 0.055))
	M.spawn_attention({
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
	M.spawn_attention({
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
	M.show(INVALID_WORD_TEXT, game().C.RED, 1.8)
end

function M.show_must_play()
	M.show(MUST_PLAY_TEXT, game().C.RED, 1.8)
end

function M.is_invalid_reason(reason)
	return reason == "Not a valid word" or reason == "Does not match"
end

function M.is_must_play_reason(reason)
	return reason == MUST_PLAY_TEXT
		or reason == "Must play a word or skip entirely"
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

function M.active_count()
	return #messages
end

function M.clear()
	messages = {}
end

function M.draw_pass()
	local dt = 0.016
	if love and love.timer and love.timer.getDelta then
		dt = math.min(0.05, love.timer.getDelta() or 0.016)
	end
	for i = #messages, 1, -1 do
		local msg = messages[i]
		msg.age = msg.age + dt
		local fade_at = msg.life * 0.5
		if msg.age <= fade_at then
			msg.alpha = 1
		else
			msg.alpha = math.max(0, 1 - (msg.age - fade_at) / math.max(0.01, msg.life - fade_at))
		end
		if msg.age >= msg.life or msg.alpha <= 0 then
			table.remove(messages, i)
		end
	end
	if #messages == 0 then return end

	local g = game()
	if not g or not g.ROOM or not g.ROOM.translate_container then return end
	local ts = (g.TILESCALE or 1) * (g.TILESIZE or 20)
	local font = board_font()
	local prev_font = love.graphics.getFont()
	local cr, cg, cb, ca = love.graphics.getColor()
	local prev_shader = love.graphics.getShader()

	love.graphics.push()
	love.graphics.setShader()
	g.ROOM:translate_container()
	love.graphics.setFont(font)
	for _, msg in ipairs(messages) do
		local a = msg.alpha or 1
		local c = msg.colour or DEFAULT_RED
		local x = msg.x * ts
		local y = msg.y * ts
		local w = msg.w * ts
		love.graphics.setColor(SHADOW[1], SHADOW[2], SHADOW[3], SHADOW[4] * a)
		love.graphics.printf(msg.text, x + 2, y + 2, w, "center")
		love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * a)
		love.graphics.printf(msg.text, x, y, w, "center")
	end
	love.graphics.pop()

	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	if prev_font then love.graphics.setFont(prev_font) end
	love.graphics.setColor(cr, cg, cb, ca)
end

return M
