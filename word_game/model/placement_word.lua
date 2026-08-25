--[[ word_game/model/placement_word.lua - Placement row word preview state on G.GAME ]]

local round = require("word_game.model.round")

local M = {}

function M.clear()
	if not G.GAME then return end
	G.GAME.placement_word = ""
	G.GAME.placement_word_valid = false
end

function M.refresh_from_cards(cards)
	if not Dictionary or not G.GAME then return end
	local ok, word = Dictionary.validate_cards(cards or {})
	if ok and round.is_word_played(word) then
		ok = false
	end
	G.GAME.placement_word = word
	G.GAME.placement_word_valid = ok
end

function M.refresh_from_jumble_slots(slots)
	if not G.GAME then return end
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if not jumble then
		M.clear()
		return
	end
	local word = jumble.build_word(slots or {})
	G.GAME.placement_word = word
	if Dictionary and word ~= "" then
		G.GAME.placement_word_valid = Dictionary.is_valid(word) and not round.is_word_played(word)
	else
		G.GAME.placement_word_valid = false
	end
end

return M
