--[[
	word_game/model/jumble/placement_word.lua - Placement row word preview.

	Core: jumbalaya_core.jumble.placement_preview (via round helpers)
	Store: SET_PLACEMENT_PREVIEW → placement_word, placement_word_valid
	Presentation: placement_word_changed
]]

local round = require("word_game.model.round")
local Presentation = require("word_game.model.presentation")
local game_access = require("word_game.model.game_access")

local M = {}

local function build_word(slots)
	local jumble = package.loaded["word_game.model.jumble"]
	if not jumble or not jumble.build_word then return "" end
	return jumble.build_word(slots or {})
end

function M.clear()
	if not game_access.get() then return end
	game_access.dispatch({ type = "SET_PLACEMENT_PREVIEW", word = "", valid = false })
	Presentation.emit("score_banner_sync_preview", true)
end

function M.refresh_from_jumble_slots(slots)
	if not game_access.get() then return end
	local word = build_word(slots)
	local valid = false
	if Dictionary and word ~= "" then
		valid = Dictionary.is_valid(word) and not round.is_word_played(word)
	end
	game_access.dispatch({ type = "SET_PLACEMENT_PREVIEW", word = word, valid = valid })
	Presentation.emit("score_banner_sync_preview", true)
end

return M
