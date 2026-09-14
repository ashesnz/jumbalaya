--[[ word_game/ui/table/token_reward/capture.lua - Reward eligibility and snapshot ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local round_config = require("jumbalaya_core.config.gameplay.round")
local session = require("word_game.ui.table.token_reward.session")

local Timeline = facade.timeline()
local RunMode = facade.run_mode()

local M = {}

local function banked_score()
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	return (j and j.total_score) or 0
end

function M.is_eligible()
	local wr = game_access.word_round()
	if not wr then return false end
	if RunMode.is_classic() then
		return true
	end
	return round_config.is_token_reward_hand(wr.set, wr.hand_index)
end

function M.earned_amount()
	if session.captured_score() ~= nil then
		return math.floor(session.captured_score())
	end
	if session.captured_time() ~= nil then
		return math.floor(session.captured_time())
	end
	if RunMode.is_classic() then
		return math.floor(banked_score())
	end
	if Timeline then
		return math.floor(Timeline.seconds_remaining())
	end
	return 0
end

function M.capture_reward()
	if not M.is_eligible() then return end
	if RunMode.is_classic() then
		if session.captured_score() ~= nil then return end
		session.set_captured_score(banked_score())
		local tt = WORD_GAME_UI.TimelineTimer
		if tt then
			tt.is_active = false
			if tt.sync_progress then tt.sync_progress() end
		end
		return
	end
	if session.captured_time() ~= nil then return end
	if Timeline then
		local captured = Timeline.seconds_remaining()
		if captured == math.huge then
			captured = 0
		end
		session.set_captured_time(captured)
		Timeline.freeze(captured)
	elseif WORD_GAME_UI.TimelineTimer then
		local tt = WORD_GAME_UI.TimelineTimer
		session.set_captured_time(tt.time_remaining or 0)
		tt.is_active = false
	end
end

return M
