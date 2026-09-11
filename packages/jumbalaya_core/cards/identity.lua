--[[ packages/jumbalaya_core/cards/identity.lua - Letter card identity (no G, no Card class) ]]

local DictionaryCards = require("jumbalaya_core.dictionary.cards")

local M = {}

local VALID_COLORS = {
	red = true,
	black = true,
	modified = true,
	gold = true,
}

function M.normalize_color(color)
	if VALID_COLORS[color] then
		return color
	end
	return "black"
end

function M.front_key(letter, color)
	if type(letter) ~= "string" or #letter < 1 then return nil end
	color = M.normalize_color(color)
	return color .. "_" .. letter:sub(1, 1):upper()
end

function M.control_for_letter(letter, color)
	return {
		key = M.front_key(letter, color),
		letter = letter,
		letter_color = color,
	}
end

function M.letter_from_id(letter_id)
	return DictionaryCards.letter_from_id(letter_id)
end

function M.is_letter_card(card)
	local letter = card and card.ability and card.ability.letter
	return type(letter) == "string" and #letter == 1
end

return M
