--[[ letter_faces.lua - Letter-card atlases and face colour ]]

local game = require("word_game.ui.util.game_runtime").game
local Palette = require "word_game.config.visuals.letter_card_palette"

local M = {}

function M.glyph_pos(letter)
	if type(letter) ~= "string" or #letter < 1 then
		return { x = 0, y = 0 }
	end
	local index = string.byte(letter:upper()) - string.byte("A") + 1
	if index < 1 or index > 26 then
		return { x = 0, y = 0 }
	end
	return { x = (index - 1) % 13, y = index <= 13 and 0 or 1 }
end

function M.fill_color(color_key)
	return Palette.fill(color_key)
end

function M.color_key_for_card(card)
	if not card then
		return Palette.DEFAULT_FACE_COLOR
	end
	if card.bonus_card then
		return Palette.BONUS_FACE_COLOR
	end
	return (card.base and card.base.color)
		or (card.ability and card.ability.letter_color)
		or (card.config and card.config.card and card.config.card.color)
		or Palette.DEFAULT_FACE_COLOR
end

function M.tint_for_card(card)
	return M.fill_color(M.color_key_for_card(card))
end

function M.is_letter_face(front)
	return type(front) == "table" and type(front.letter) == "string" and #front.letter == 1
end

function M.is_letter_card(card)
	if not card then return false end
	if M.is_letter_face(card.config and card.config.card) then
		return true
	end
	local letter = card.ability and card.ability.letter
	return type(letter) == "string" and #letter == 1
end

function M.atlas(name)
	return game().TEXTURE_ATLASES and game().TEXTURE_ATLASES[name]
end

function M.frame_atlas()
	return M.atlas("letter_frame")
end

function M.letters_atlas()
	return M.atlas("letters")
end

--- Marketplace fly FX: coloured frame, then the letter glyph.
function M.draw_composite(x, y, rot, pw, ph, letter, color_key, alpha)
	if not love or not love.graphics then return end
	local frame_atlas = M.frame_atlas()
	local letters_atlas = M.letters_atlas()
	if not frame_atlas or not letters_atlas or not frame_atlas.image or not letters_atlas.image then
		return
	end

	local pos = M.glyph_pos(letter)
	local fill = M.fill_color(color_key)
	local a = alpha or 1

	local function draw_layer(atlas, sprite_pos, tint)
		local cell_w, cell_h = atlas.px or 71, atlas.py or 95
		local iw, ih = atlas.image:getDimensions()
		local quad = love.graphics.newQuad(
			sprite_pos.x * cell_w, sprite_pos.y * cell_h,
			cell_w, cell_h, iw, ih)
		love.graphics.setColor(tint[1], tint[2], tint[3], a)
		love.graphics.draw(atlas.image, quad, x, y, rot or 0, pw / cell_w, ph / cell_h, cell_w * 0.5, cell_h * 0.5)
	end

	draw_layer(frame_atlas, { x = 0, y = 0 }, fill)
	draw_layer(letters_atlas, pos, { 1, 1, 1 })
end

return M
