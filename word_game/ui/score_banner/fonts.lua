--[[
	word_game/ui/score_banner/fonts.lua - Title and bubble fonts, score shader helpers.
]]

local M = {}

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local BUBBLE_FONT_FILE = "resources/fonts/Sniglet-ExtraBold.ttf"
local font_cache = {}
local bubble_font_cache = {}

local function title_font(px)
	px = math.max(12, math.floor(px + 0.5))
	local cached = font_cache[px]
	if cached then return cached end
	local ok, font = pcall(love.graphics.newFont, FONT_FILE, px)
	if not ok or not font then
		font = love.graphics.newFont(px)
	end
	if font.setFilter then font:setFilter("linear", "linear") end
	font_cache[px] = font
	return font
end

local function bubble_font(px)
	px = math.max(12, math.floor(px + 0.5))
	local cached = bubble_font_cache[px]
	if cached then return cached end
	local ok, font = pcall(love.graphics.newFont, BUBBLE_FONT_FILE, px)
	if not ok or not font then
		ok, font = pcall(love.graphics.newFont, FONT_FILE, px)
	end
	if not ok or not font then
		font = love.graphics.newFont(px)
	end
	if font.setFilter then font:setFilter("linear", "linear") end
	bubble_font_cache[px] = font
	return font
end

function M.title_font(px)
	return title_font(px)
end

function M.bubble_font(px)
	return bubble_font(px)
end

function M.set_score_shader(bounce_amount, is_mult)
	local sh = G and G.SHADERS and G.SHADERS.score_bubble
	if not sh or not love.graphics.setShader then return end
	pcall(function()
		sh:send("time", (G.TIMERS and G.TIMERS.REAL) or 0)
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
