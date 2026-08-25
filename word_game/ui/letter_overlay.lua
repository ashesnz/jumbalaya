--[[ word_game/ui/letter_overlay.lua - AP values on playing-card corners ]]

local M = {}

local function draw_corner_value(ap_text, font, x, y, rot, scale)
	local fw = font:getWidth(ap_text)
	local fh = font:getHeight()
	love.graphics.print(ap_text, x, y, rot, scale, scale, fw / 2, fh / 2)
end

function M.draw(card)
	if not card then return end
	if card.facing == "back" or card.sprite_facing == "back" then return end
	if card.area == G.deck then return end
	local letter = card.ability and card.ability.letter
	if not letter or not card.VT then return end

	local wr = G.GAME and G.GAME.word_round
	local dynamic_value = wr and wr.dynamic_letter_values and wr.dynamic_letter_values[letter]
	
	-- Only draw if there's a dynamic value (requirement says take off static numbers)
	if not dynamic_value then return end

	local font = G.LANG and G.LANG.font
	if not font or not font.FONT then return end

	local ap_text = tostring(dynamic_value)
	local prev_font = love.graphics.getFont()

	push_node_transform(card, 1)
	local w, h = card.VT.w, card.VT.h
	love.graphics.setFont(font.FONT)
	local fh = font.FONT:getHeight()
	local small_scale = (h * 0.11) / fh

	-- Face art already has the gothic letter. Stamp AP where the small corner label sat.
	love.graphics.setColor(1, 1, 1, 1)
	draw_corner_value(ap_text, font.FONT, w * 0.18, h * 0.12, 0, small_scale)
	draw_corner_value(ap_text, font.FONT, w * 0.82, h * 0.88, math.pi, small_scale)

	love.graphics.pop()
	if prev_font then love.graphics.setFont(prev_font) end
	love.graphics.setColor(1, 1, 1, 1)
end

return M
