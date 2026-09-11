--[[ word_game/model/round/init.lua - Set / hand controller (glue over jumbalaya_core + store) ]]

local state = require("word_game.model.run.state")
local game_access = require("word_game.model.game_access")
local Presentation = require("word_game.model.presentation")
local core_round = require("jumbalaya_core.round")
local core_jumble_hand = require("jumbalaya_core.jumble.hand")

local M = {}

function M.init_run()
	state.get()
	game_access.dispatch({ type = "ROUND_INIT_RUN" })
	M.start_hand(1, 1)
end

function M.restore_from_save()
	state.get()
	local wr = game_access.word_round()
	if not wr then
		M.init_run()
		return
	end
	core_round.normalize_saved_word_round(wr)
	Presentation.emit("round_restore_from_save", wr)
end

function M.start_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	game_access.dispatch({
		type = "ROUND_START_HAND",
		set = set,
		hand_index = hand_index,
		trade_reset = true,
	})

	local wr = game_access.word_round()
	if not core_jumble_hand.clear_if_inactive_hand(wr, set, hand_index) then
		require("word_game.model.jumble").start_hand(wr)
	end

	Presentation.emit("hand_started", set, hand_index)
end

function M.is_word_played(word)
	return core_round.is_word_played(game_access.word_round(), word)
end

function M.record_word_play(word)
	game_access.dispatch({ type = "ROUND_RECORD_WORD", word = word })
end

function M.is_final_hand()
	return core_round.is_final_hand(game_access.word_round())
end

function M.advance_hand()
	local wr = game_access.word_round()
	if not wr then return "none" end

	local action, next_set, next_hand = core_round.advance_hand(wr)
	if action == "win" then
		return "win"
	end
	if action == "next_set" then
		M.start_hand(next_set, next_hand)
		return "next_set"
	end
	if action == "next" then
		M.start_hand(next_set, next_hand)
		return "next"
	end
	return "none"
end

function M.reset_timeline()
	Presentation.emit("timeline_reset")
end

return M
