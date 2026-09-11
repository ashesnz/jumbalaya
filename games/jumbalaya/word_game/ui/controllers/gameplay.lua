--[[ word_game/ui/controllers/gameplay.lua - Phase 4 gameplay runtime().FUNCS controller ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local action_dispatch = require("app.input.action_dispatch")
local game_access = require("word_game.model.game_access")
local TableControls = require("word_game.ui.table.controls")

local M = {}

function M.play_word_extra()
	local game = game_access.get()
	if not game or not game.placement_word or game.placement_word == "" then
		return nil
	end
	return { word = game.placement_word }
end

function M.shuffle_hand(e)
	action_dispatch.dispatch_func("shuffle_hand")
	TableControls.shuffle_hand(e)
end

function M.return_placement_cards(e)
	action_dispatch.dispatch_func("return_placement_cards")
	TableControls.return_placement_cards_to_hand(e)
end

function M.play_placement_word(e)
	action_dispatch.dispatch_func("play_placement_word", M.play_word_extra())
	TableControls.play(e)
end

function M.jumble_next(e)
	action_dispatch.dispatch_func("jumble_next")
	TableControls.jumble_next(e)
end

return M
