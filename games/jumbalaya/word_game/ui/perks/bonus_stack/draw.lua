--[[ word_game/ui/perks/bonus_stack/draw.lua - Bonus gutter card pass ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")

local function bonus_stack_model()
	return facade.bonus_stack()
end

local M = {}

local function draw_label(layout)
	if not bonus_stack_model().is_active() then return end
	local font = game().FONTS and (game().FONTS.sm or game().FONTS.medium or game().FONTS.main)
	if not font then return end
	love.graphics.setFont(font)
	love.graphics.setColor(1, 0.92, 0.55, 0.95)
	local scale = 0.34
	local text = "Bonus Cards"
	local tw = font:getWidth(text) * scale
	love.graphics.print(text, layout.x + (layout.card_w - tw) * 0.5, layout.label_y, 0, scale, scale)
	love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_pass(layout_mod)
	local cards = bonus_stack_model().cards()
	if not cards then return end
	local layout = layout_mod.stack_layout()
	if bonus_stack_model().is_active() and not bonus_stack_model().is_animating() then
		draw_label(layout)
	end
	local dragging = game().INPUT and game().INPUT.dragging and game().INPUT.dragging.target
	local focused = game().INPUT and game().INPUT.focused and game().INPUT.focused.target
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
