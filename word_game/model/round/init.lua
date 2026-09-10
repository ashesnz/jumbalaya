--[[ word_game/model/round/init.lua - Set / hand controller ]]
local Scheduler = require "app.effects.timeline_scheduler"


local round_config = require("word_game.config.gameplay.round")
local RunMode = require("word_game.model.run.mode")
local state = require("word_game.model.run.state")
local Presentation = require("word_game.model.presentation")

local M = {}

function M.init_run()
	state.get()
	G.GAME.word_round = {
		set = 1,
		hand_index = 1,
		target = round_config.hand_target(1, 1),
		played_words = {},
	}
	G.GAME.voucher_discards_used = 0
	G.GAME.discard_bin_count = 0
	G.GAME.round_resets = G.GAME.round_resets or {}
	G.GAME.round_resets.ante = 1
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
	G.GAME.round_resets = G.GAME.round_resets or {}
	G.GAME.round_resets.ante = wr.set
	Presentation.emit("round_restore_from_save", wr)
end

function M.start_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	local rs = state.get()
	if rs then
		rs.trade_used_this_hand = false
	end

	G.GAME.word_round = G.GAME.word_round or {}
	local wr = G.GAME.word_round
	wr.set = set
	wr.hand_index = hand_index
	wr.target = round_config.hand_target(set, hand_index)
	wr.hand_name = round_config.hand_name(hand_index, set)
	wr.played_words = {}

	local jumble = require("word_game.model.jumble")
	if jumble.is_active_hand(set, hand_index) then
		jumble.start_hand(wr)
	elseif wr.mode == "jumble" then
		wr.mode = nil
		wr.jumble = nil
	end

	G.GAME.round_resets = G.GAME.round_resets or {}
	G.GAME.round_resets.ante = set

	Presentation.emit("hand_started", set, hand_index)
end

function M.is_word_played(word)
	if not word or word == "" then return false end
	word = string.upper(word)
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.played_words and wr.played_words[word]
end

function M.record_word_play(word)
	if not word or word == "" then return end
	word = string.upper(word)
	local wr = G.GAME and G.GAME.word_round
	if wr then
		wr.played_words = wr.played_words or {}
		wr.played_words[word] = true
	end
end

function M.is_final_hand()
	local wr = G.GAME and G.GAME.word_round
	if not wr then return false end
	return wr.set >= round_config.SETS_TO_WIN
		and wr.hand_index >= round_config.hands_in_set(wr.set)
end

function M.advance_hand()
	local wr = G.GAME and G.GAME.word_round
	if not wr then return "none" end

	if wr.hand_index >= round_config.hands_in_set(wr.set) then
		if wr.set >= round_config.SETS_TO_WIN then
			return "win"
		end
		M.start_hand(wr.set + 1, 1)
		return "next_set"
	end

	M.start_hand(wr.set, wr.hand_index + 1)
	return "next"
end

function M.reset_timeline()
	Presentation.emit("timeline_reset")
end

return M
