--[[ word_game/ui/table/token_reward/draw.lua - Coin sticker draw pass ]]

local GameRT = require("word_game.ui.util.game_runtime")
local facade = require("word_game.ui.facade")
local session = require("word_game.ui.table.token_reward.session")
local layout = require("word_game.ui.table.token_reward.layout")
local flyers = require("word_game.ui.table.token_reward.flyers")

local game_access = facade.game_access()

local M = {}

local function runtime()
	return GameRT.game()
end

function M.draw_pass()
	if not session.is_active() and #session.flyers() == 0 then return end
	if not game_access.get() or not runtime().ROOM then return end
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD then return end

	flyers.update(math.min(0.05, love.timer and love.timer.getDelta() or 0.016))

	local img, quad, pw, ph = layout.sticker_quad()
	if not img or not quad then return end

	local ts = (runtime().TILESCALE or 1) * (runtime().TILESIZE or 1)
	local size = math.max(22, runtime().CARD_W * ts * 0.16)
	local scale = size / pw

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()
	love.graphics.setShader()
	layout.room_translate()

	for _, f in ipairs(session.flyers()) do
		local a = f.alpha or 1
		love.graphics.setColor(1, 1, 1, a)
		love.graphics.draw(img, quad, f.x, f.y, f.rot or 0, scale, scale, pw * 0.5, ph * 0.5)
		if a > 0.35 then
			love.graphics.setColor(1, 0.92, 0.45, a * 0.22)
			love.graphics.draw(img, quad, f.x, f.y, f.rot or 0, scale * 1.18, scale * 1.18, pw * 0.5, ph * 0.5)
		end
	end

	love.graphics.pop()
	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	love.graphics.setColor(cr, cg, cb, ca)
end

return M
