--[[ word_game/ui/table/controls/placement.lua - Play button entry (G.FUNCS.play_placement_word) ]]

local facade = require("word_game.ui.facade")
local word_feedback = require("word_game.ui.feedback.word_feedback")
local play_resolution = require("word_game.ui.play_effects.resolution")

local InputLock = facade.input_lock()
local RunMode = facade.run_mode()

local M = {}

function M.try_play()
	if InputLock.is_table_busy() then return end
	if RunMode.classic_stage_complete() then
		local hand_shuffle = WORD_GAME and WORD_GAME.HandShuffle
		if not (hand_shuffle and hand_shuffle.placement_has_cards()) then
			word_feedback.show_classic_proceed({ hold = 2.2 })
		elseif WORD_GAME and WORD_GAME.Play then
			play_resolution.resolve(WORD_GAME.Play)
		end
		return
	end
	if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.consume_click() then return end
	if WORD_GAME and WORD_GAME.Play then
		play_resolution.resolve(WORD_GAME.Play)
	end
end

return M
