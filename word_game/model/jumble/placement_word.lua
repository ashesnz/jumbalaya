--[[ word_game/model/jumble/placement_word.lua - Placement row word preview on G.GAME ]]

local round = require("word_game.model.round")
local Presentation = require("word_game.model.presentation")

local M = {}

local function build_word(slots)
	local jumble = package.loaded["word_game.model.jumble"]
	if not jumble or not jumble.build_word then return "" end
	return jumble.build_word(slots or {})
end

function M.clear()
	if not G.GAME then return end
	G.GAME.placement_word = ""
	G.GAME.placement_word_valid = false
	Presentation.emit("score_banner_sync_preview", true)
end

function M.refresh_from_jumble_slots(slots)
	if not G.GAME then return end
	local word = build_word(slots)
	G.GAME.placement_word = word
	if Dictionary and word ~= "" then
		G.GAME.placement_word_valid = Dictionary.is_valid(word) and not round.is_word_played(word)
	else
		G.GAME.placement_word_valid = false
	end
	Presentation.emit("score_banner_sync_preview", true)
end

return M
