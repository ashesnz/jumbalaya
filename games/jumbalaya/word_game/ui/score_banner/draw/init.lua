--[[ word_game/ui/score_banner/draw/init.lua - Jumble score banner rendering ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local GameRT = require("word_game.ui.util.game_runtime")
local Layout = require("word_game.ui.layout")
local felt_layout = require("word_game.ui.layout.felt")
local boss_word_announce = require("word_game.ui.score_banner.boss_announce")
local helpers = require("word_game.ui.score_banner.draw.helpers")
local chips = require("word_game.ui.score_banner.draw.chips")
local equation = require("word_game.ui.score_banner.draw.equation")

local M = {}

local function runtime()
	return GameRT.game()
end

function M.draw(sb)
	if not game_access.get() or not runtime().ROOM then return end
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD then return end

	local dt = math.min(0.05, love.timer.getDelta())
	sb.update(dt)
	sb.decay_pulse(dt)

	local game = game_access.get()
	local hud_early = game and game.word_hud
	local mode_early = hud_early and hud_early.banner_mode or "normal"
	if mode_early ~= "boss_prep" and mode_early ~= "boss_word"
		and not boss_word_announce.is_active()
		and felt_layout.is_boss_sequence() then
		return
	end

	local ts = runtime().TILESCALE * runtime().TILESIZE
	local rect = Layout.banner_rect()
	local w = rect.w * ts
	local h = rect.h * ts
	local slant = rect.slant * ts
	local x = rect.x * ts
	local y = rect.y * ts

	local prev_font = love.graphics.getFont and love.graphics.getFont()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	local prev_shader = love.graphics.getShader and love.graphics.getShader()

	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	helpers.room_translate()

	local mid_y = y + h * 0.5
	if love.graphics.setLineStyle then love.graphics.setLineStyle("smooth") end
	if love.graphics.setLineJoin then love.graphics.setLineJoin("bevel") end

	local breathe = helpers.ease_inout((math.sin((runtime().TIMERS.REAL or 0) * math.pi * 2 / 3) * 1.3 + 1) / 2)
	local pulse_s = 1 + sb.pulse_value() * 0.1
	local cx = x + w * 0.5
	local cy = mid_y

	love.graphics.push()
	love.graphics.translate(cx, cy)
	love.graphics.scale(pulse_s, pulse_s * (1 + breathe * 0.02))

	local layout = sb.calc_layout(w, h, slant)

	local hud = game and game.word_hud
	local banner_mode = hud and hud.banner_mode or "normal"
	if banner_mode == "boss_prep" or banner_mode == "boss_word"
		or boss_word_announce.is_active() then
		love.graphics.pop()
		love.graphics.pop()
		if prev_shader and love.graphics.setShader then
			love.graphics.setShader(prev_shader)
		elseif love.graphics.setShader then
			love.graphics.setShader()
		end
		if prev_font and love.graphics.setFont then love.graphics.setFont(prev_font) end
		if love.graphics.setColor then love.graphics.setColor(cr, cg, cb, ca) end
		return
	end

	chips.draw(sb, layout, w, h)
	equation.draw(sb, cx, ts, h)

	love.graphics.pop()
	love.graphics.pop()
	if prev_shader and love.graphics.setShader then
		love.graphics.setShader(prev_shader)
	elseif love.graphics.setShader then
		love.graphics.setShader()
	end
	if prev_font and love.graphics.setFont then love.graphics.setFont(prev_font) end
	if love.graphics.setColor then love.graphics.setColor(cr, cg, cb, ca) end
end

return M
