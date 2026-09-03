-- Jumbalaya placement controls.

local InputLock = require("word_game.model.input_lock")
local RunMode = require("word_game.model.run_mode")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

local function placement_has_cards()
	local hand_shuffle = WORD_GAME and WORD_GAME.HandShuffle
	return hand_shuffle
		and hand_shuffle.placement_has_cards
		and hand_shuffle.placement_has_cards()
end

function M.try_play()
	if InputLock.is_table_busy() then return end
	if RunMode.classic_stage_complete() then
		if not placement_has_cards() then
			word_feedback.show_classic_proceed({ hold = 2.2 })
		end
		return
	end
	if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.consume_click() then return end
	if WORD_GAME and WORD_GAME.Play then
		WORD_GAME.Play.play_word()
	end
end

G.FUNCS.play_placement_word = M.try_play

return M
