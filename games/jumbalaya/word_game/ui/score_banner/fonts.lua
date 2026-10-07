--[[
	word_game/ui/score_banner/fonts.lua - Title and bubble fonts, score shader helpers.
]]

local game = require("word_game.ui.util.game_runtime").game
local GameFonts = require("word_game.ui.util.fonts")

local M = {}

local function title_font(px)
	px = math.max(12, math.floor(px + 0.5))
	return GameFonts.outfit(px)
end

local function bubble_font(px)
	px = math.max(12, math.floor(px + 0.5))
	return GameFonts.sniglet(px)
end

function M.title_font(px)
	return title_font(px)
end

function M.bubble_font(px)
	return bubble_font(px)
end

function M.set_score_shader(bounce_amount, is_mult)
	local sh = game() and game().SHADERS and game().SHADERS.score_bubble
	if not sh or not love.graphics.setShader then return end
	pcall(function()
		sh:send("time", (game().TIMERS and game().TIMERS.REAL) or 0)
		sh:send("bounce_amount", bounce_amount or 0)
		sh:send("is_mult", is_mult and 1.0 or 0.0)
	end)
	love.graphics.setShader(sh)
end

function M.reset_score_shader()
	if love.graphics.setShader then
		love.graphics.setShader()
	end
end

return M
