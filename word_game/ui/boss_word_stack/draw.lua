--[[ word_game/ui/boss_word_stack/draw.lua - Bonus gutter backdrop and card pass ]]

local model = require("word_game.model.bonus_stack")
local board_config = require("word_game.board.config")

local M = {}

local BACKDROP_FILL_ALPHA = 0.18
local BACKDROP_LINE_ALPHA = 0.28

local function stack()
	return require("word_game.ui.boss_word_stack")
end

local function draw_label(layout)
	if not stack().is_active() then return end
	local font = G.FONTS and (G.FONTS.sm or G.FONTS.medium or G.FONTS.main)
	if not font then return end
	love.graphics.setFont(font)
	love.graphics.setColor(1, 0.92, 0.55, 0.95)
	local scale = 0.34
	local text = "Bonus Cards"
	local tw = font:getWidth(text) * scale
	love.graphics.print(text, layout.x + (layout.card_w - tw) * 0.5, layout.label_y, 0, scale, scale)
	love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_shadow(layout_mod)
	local cards = model.cards()
	if not cards or #cards == 0 then return end
	local layout = layout_mod.stack_layout()
	local px, py, pw, ph = layout_mod.gutter_pixels(layout)
	local radius = board_config.CORNER_RADIUS or 8

	love.graphics.setColor(0, 0, 0, BACKDROP_FILL_ALPHA)
	love.graphics.rectangle("fill", px, py, pw, ph, radius, radius)
	love.graphics.setColor(1, 1, 1, BACKDROP_LINE_ALPHA)
	love.graphics.setLineWidth(1.5)
	love.graphics.rectangle("line", px, py, pw, ph, radius, radius)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
end

function M.draw_pass(layout_mod)
	local cards = model.cards()
	if not cards then return end
	local layout = layout_mod.stack_layout()
	if stack().is_active() and not model.is_animating() then
		draw_label(layout)
	end
	local dragging = G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target
	local focused = G.INPUT and G.INPUT.focused and G.INPUT.focused.target
	for _, card in ipairs(cards) do
		if card and not card.REMOVED and not card.area
			and card ~= dragging and card ~= focused then
			love.graphics.push()
			card:translate_container()
			card:draw()
			love.graphics.pop()
		end
	end
end

return M
