--[[ word_game/model/round.lua - Set / Hand / Showdown controller ]]
local Scheduler = require "app.effects.scheduler"


local round_config = require("word_game.config.round_config")
local economy = require("word_game.config.economy")
local state = require("word_game.model.state")

local M = {}

local function refresh()
	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar:refresh()
	end
end

function M.init_run()
	state.get()
	local alpha = state.get()
	G.GAME.word_round = {
		set = 1,
		hand_index = 1,
		plays_left = round_config.PLAYS_PER_HAND,
		redraws_left = round_config.REDRAWS_PER_HAND,
		target = round_config.hand_target(1, 1),
		played_words = {},
	}
	G.GAME.table_word_history = {}
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
	wr.plays_left = wr.plays_left or round_config.PLAYS_PER_HAND
	wr.words_left = wr.words_left or wr.plays_left
	wr.redraws_left = wr.redraws_left or round_config.REDRAWS_PER_HAND
	wr.target = wr.target or round_config.hand_target(wr.set, wr.hand_index)
	wr.hand_name = wr.hand_name or round_config.hand_name(wr.hand_index)
	G.GAME.round_resets = G.GAME.round_resets or {}
	G.GAME.round_resets.ante = wr.set
	G.GAME.points = G.GAME.points or 0
	if WORD_GAME and WORD_GAME.ScoreBanner then
		WORD_GAME.ScoreBanner.reset(wr.target)
		WORD_GAME.ScoreBanner.snap_to_actual()
	end
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.reset then
		WORD_GAME.TimelineTimer.reset(60.0)
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
	wr.plays_left = round_config.PLAYS_PER_HAND
	wr.words_left = wr.plays_left
	wr.redraws_left = round_config.REDRAWS_PER_HAND
	wr.target = round_config.hand_target(set, hand_index)
	wr.hand_name = round_config.hand_name(hand_index)
	wr.played_words = {}
	wr.boss_character = nil

	-- Dynamic values
	wr.dynamic_letter_values = nil

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

	-- 60s timeline for all jumble puzzle phases (including 1-3 pre-boss).
	local jumble = require("word_game.model.jumble")
	if jumble.is_active_hand(set, hand_index)
		and WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.reset then
		WORD_GAME.TimelineTimer.reset(60.0)
	end

	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar:clear_hand()
	end

	refresh()

	if WORD_GAME and WORD_GAME.Characters and WORD_GAME.Characters.apply_hand_cast then
		WORD_GAME.Characters.apply_hand_cast(set, hand_index)
	end

	local backgrounds = require "word_game.ui.layout.backgrounds"
	backgrounds.stage(set, hand_index)
end

-- Uppercase index over table_word_history, rebuilt lazily when the log's
-- length changes (entries are append/clear only). Keeps the per-word
-- duplicate check O(1) even when the hot paths ask thousands of times.
local history_index = nil
local history_index_len = -1

function M.is_word_played(word)
	if not word or word == "" then return false end
	word = string.upper(word)
	local wr = G.GAME and G.GAME.word_round
	if wr and wr.played_words and wr.played_words[word] then
		return true
	end
	local history = G.GAME and G.GAME.table_word_history
	if not history then return false end

	if history_index == nil or history_index_len ~= #history then
		history_index = {}
		for _, entry in ipairs(history) do
			if entry and entry.word then
				history_index[string.upper(entry.word)] = true
			end
		end
		history_index_len = #history
	end
	return history_index[word] == true
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

function M.use_word_play()
	local wr = G.GAME.word_round
	if not wr then return end
	local from = wr.plays_left or 0
	wr.plays_left = math.max(0, from - 1)
	wr.words_left = wr.plays_left
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.roll_plays then
		WORD_GAME.Sidebar.roll_plays(from, wr.plays_left)
	end
	refresh()
end

function M.add_play()
	local wr = G.GAME.word_round
	if not wr then return end
	wr.plays_left = (wr.plays_left or 0) + 1
	wr.words_left = wr.plays_left
	refresh()
end

function M.hand_cleared()
	return (G.GAME.points or 0) >= (G.GAME.word_round and G.GAME.word_round.target or 0)
end

function M.out_of_plays()
	return (G.GAME.word_round and G.GAME.word_round.plays_left or 0) <= 0
end

M.out_of_words = M.out_of_plays

function M.is_final_hand()
	local wr = G.GAME.word_round
	return wr and wr.set >= round_config.SETS_TO_WIN and round_config.is_showdown(wr.hand_index)
end

function M.advance_hand()
	local wr = G.GAME.word_round
	if not wr then return "next" end

	if round_config.is_showdown(wr.hand_index) then
		if wr.set >= round_config.SETS_TO_WIN then
			return "win"
		end
		M.start_hand(wr.set + 1, 1)
		return "next_set"
	end

	if wr.set == 1 and wr.hand_index == 4 then
		M.start_hand(2, 1)
		return "next_set"
	end

	M.start_hand(wr.set, wr.hand_index + 1)
	return "next"
end

function M.unused_play_payout()
	local wr = G.GAME.word_round
	if not wr then return 0 end
	local unused = wr.plays_left or 0
	local points = economy.hand_payout(unused)
	state.earn(points)
	return points
end

M.unused_word_payout = M.unused_play_payout

function M.display_hand_name()
	local wr = G.GAME.word_round
	if not wr then return "Hand" end
	return (wr.hand_name or "Standard") .. " Hand"
end

return M
