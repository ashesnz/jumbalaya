--[[ word_game/model/round/init.lua - Set / hand controller (G glue over jumbalaya_core + store) ]]

local round_config = require("word_game.config.gameplay.round")
local state = require("word_game.model.run.state")
local game_access = require("word_game.model.game_access")
local Presentation = require("word_game.model.presentation")
local core_round = require("jumbalaya_core.round")
local store_sync = require("bridge.store_sync")

local M = {}

local function dispatch(action)
	if G and G._store then
		store_sync.dispatch(G._store, action)
	else
		local game = game_access.get()
		if not game then return end
		if action.type == "ROUND_INIT_RUN" then
			game.word_round = core_round.new_word_round(1, 1)
			for key, value in pairs(core_round.run_reset_fields()) do
				game[key] = value
			end
		elseif action.type == "ROUND_START_HAND" then
			game.word_round = core_round.start_hand_coords(action.set, action.hand_index)
			if action.trade_reset then
				local rs = state.get()
				if rs then rs.trade_used_this_hand = false end
			end
		elseif action.type == "ROUND_RECORD_WORD" then
			core_round.record_word_play(game.word_round, action.word)
		end
	end
end

function M.init_run()
	state.get()
	dispatch({ type = "ROUND_INIT_RUN" })
	M.start_hand(1, 1)
end

function M.restore_from_save()
	state.get()
	local wr = game_access.word_round()
	if not wr then
		M.init_run()
		return
	end
	wr.set = wr.set or 1
	wr.hand_index = wr.hand_index or 1
	wr.target = wr.target or round_config.hand_target(wr.set, wr.hand_index)
	wr.hand_name = wr.hand_name or round_config.hand_name(wr.hand_index, wr.set)
	if G._store then
		store_sync.sync_from_g(G._store)
		store_sync.sync_to_g(G._store)
	end
	Presentation.emit("round_restore_from_save", wr)
end

function M.start_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	dispatch({
		type = "ROUND_START_HAND",
		set = set,
		hand_index = hand_index,
		trade_reset = true,
	})

	local wr = game_access.word_round()
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
	return core_round.is_word_played(game_access.word_round(), word)
end

function M.record_word_play(word)
	dispatch({ type = "ROUND_RECORD_WORD", word = word })
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
