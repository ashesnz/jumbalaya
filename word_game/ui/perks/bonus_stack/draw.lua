--[[ word_game/ui/perks/bonus_stack/draw.lua - Bonus gutter card pass ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")

local function bonus_stack_model()
	return facade.bonus_stack()
end

local M = {}

local function draw_label(layout)
	if not bonus_stack_model().is_active() then return end
	local font = runtime().FONTS and (runtime().FONTS.sm or runtime().FONTS.medium or runtime().FONTS.main)
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
	local dragging = runtime().INPUT and runtime().INPUT.dragging and runtime().INPUT.dragging.target
	local focused = runtime().INPUT and runtime().INPUT.focused and runtime().INPUT.focused.target
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
