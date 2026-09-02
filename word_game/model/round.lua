--[[ word_game/model/round.lua - Set / Hand controller ]]
local Scheduler = require "app.effects.scheduler"


local round_config = require("word_game.config.round_config")
local state = require("word_game.model.state")

local M = {}

local function refresh()
	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar:refresh()
	end
end

function M.init_run()
	state.get()
	G.GAME.word_round = {
		set = 1,
		hand_index = 1,
		target = round_config.hand_target(1, 1),
		played_words = {},
	}
	G.GAME.points = 0
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
	G.GAME.points = G.GAME.points or 0
	if WORD_GAME and WORD_GAME.ScoreBanner then
		WORD_GAME.ScoreBanner.reset(wr.target)
		WORD_GAME.ScoreBanner.snap_to_actual()
	end
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.reset then
		WORD_GAME.	TimelineTimer.reset(60.0)
	end
	if WORD_GAME and WORD_GAME.StageLabel and WORD_GAME.StageLabel.force_sync then
		WORD_GAME.StageLabel.force_sync()
	end
	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar:ensure()
		WORD_GAME.Sidebar:refresh()
	end
	refresh()
	local backgrounds = require "word_game.ui.layout.backgrounds"
	backgrounds.stage(wr.set, wr.hand_index)
end

function M.start_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	local alpha = state.get()
	if alpha then
		alpha.trade_used_this_hand = false
	end

	G.GAME.word_round = G.GAME.word_round or {}
	local wr = G.GAME.word_round
	wr.set = set
	wr.hand_index = hand_index
	wr.target = round_config.hand_target(set, hand_index)
	wr.hand_name = round_config.hand_name(hand_index, set)
	wr.played_words = {}
	wr.boss_character = nil

	if WORD_GAME and WORD_GAME.BossWordStack and WORD_GAME.BossWordStack.on_hand_start then
		WORD_GAME.BossWordStack.on_hand_start(set, hand_index)
	end

	local jumble = require("word_game.model.jumble")
	if jumble.is_active_hand(set, hand_index) then
		jumble.start_hand(wr)
	elseif wr.mode == "jumble" then
		wr.mode = nil
		wr.jumble = nil
	end

	G.GAME.round_resets = G.GAME.round_resets or {}
	G.GAME.round_resets.ante = set
	G.GAME.points = 0

	if WORD_GAME and WORD_GAME.ScoreBanner then
		WORD_GAME.ScoreBanner.reset(wr.target)
	end

	local jumble = require("word_game.model.jumble")
	if jumble.is_active_hand(set, hand_index)
		and WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.reset then
		WORD_GAME.TimelineTimer.reset(60.0)
	end

	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.clear_hand then
		WORD_GAME.Sidebar:clear_hand()
	end

	if WORD_GAME and WORD_GAME.StageLabel and WORD_GAME.StageLabel.sync then
		WORD_GAME.StageLabel.sync()
	end

	refresh()

	if WORD_GAME and WORD_GAME.Characters and WORD_GAME.Characters.apply_hand_cast then
		WORD_GAME.Characters.apply_hand_cast(set, hand_index)
	end

	local backgrounds = require "word_game.ui.layout.backgrounds"
	backgrounds.stage(set, hand_index)
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

function M.refresh_hud()
	refresh()
end

function M.add_score(amount)
	G.GAME.points = (G.GAME.points or 0) + amount
	refresh()
end

function M.hand_cleared()
	return (G.GAME.points or 0) >= (G.GAME.word_round and G.GAME.word_round.target or 0)
end

function M.is_final_hand()
	local wr = G.GAME.word_round
	return wr and round_config.is_final_hand(wr.set, wr.hand_index)
end

function M.advance_hand()
	local wr = G.GAME.word_round
	if not wr then return "next" end

	if round_config.is_final_hand(wr.set, wr.hand_index) then
		return "win"
	end

	local hands = round_config.hands_in_set(wr.set)
	if wr.hand_index >= hands then
		M.start_hand(wr.set + 1, 1)
		return "next_set"
	end

	M.start_hand(wr.set, wr.hand_index + 1)
	return "next"
end

function M.display_hand_name()
	local wr = G.GAME.word_round
	if not wr then return "Hand" end
	return (wr.hand_name or "Standard") .. " Hand"
end

return M
