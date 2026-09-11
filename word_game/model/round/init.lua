--[[ word_game/model/round/init.lua - Set / hand controller (G glue over jumbalaya_core) ]]

local round_config = require("word_game.config.gameplay.round")
local state = require("word_game.model.run.state")
local Presentation = require("word_game.model.presentation")
local core_round = require("jumbalaya_core.round")

local M = {}

function M.init_run()
	state.get()
	G.GAME.word_round = core_round.new_word_round(1, 1)
	for key, value in pairs(core_round.run_reset_fields()) do
		G.GAME[key] = value
	end
	M.start_hand(1, 1)
end

function M.restore_from_save()
	state.get()
	local wr = G.GAME.word_round
	if not wr then
		M.init_run()
		return
	end
	wr.set = wr.set or 1
	wr.hand_index = wr.hand_index or 1
	wr.target = wr.target or round_config.hand_target(wr.set, wr.hand_index)
	wr.hand_name = wr.hand_name or round_config.hand_name(wr.hand_index, wr.set)
	Presentation.emit("round_restore_from_save", wr)
end

function M.start_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	local rs = state.get()
	if rs then
		rs.trade_used_this_hand = false
	end

	local wr = core_round.start_hand_coords(set, hand_index)
	G.GAME.word_round = wr

	local jumble = require("word_game.model.jumble")
	if jumble.is_active_hand(set, hand_index) then
		jumble.start_hand(wr)
	elseif wr.mode == "jumble" then
		wr.mode = nil
		wr.jumble = nil
	end

	Presentation.emit("hand_started", set, hand_index)
end

function M.is_word_played(word)
	local wr = G.GAME and G.GAME.word_round
	return core_round.is_word_played(wr, word)
end

function M.record_word_play(word)
	local wr = G.GAME and G.GAME.word_round
	core_round.record_word_play(wr, word)
end

function M.is_final_hand()
	local wr = G.GAME and G.GAME.word_round
	return core_round.is_final_hand(wr)
end

function M.advance_hand()
	local wr = G.GAME and G.GAME.word_round
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
