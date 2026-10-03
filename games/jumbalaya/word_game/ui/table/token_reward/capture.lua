--[[ word_game/ui/table/token_reward/capture.lua - Reward eligibility and snapshot ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local round_config = require("jumbalaya_core.config.gameplay.round")
local session = require("word_game.ui.table.token_reward.session")

local Timeline = facade.timeline()
local RunMode = facade.run_mode()
local core_jumble = require("jumbalaya_core.rules.jumble")

local M = {}

--- Banked stage score including the current puzzle (matches classic fuse / 35 of 25 UI).
local function banked_score()
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	if not j then return 0 end
	return core_jumble.committed_earned(j)
end

local function freeze_classic_timer()
	local tt = WORD_GAME_UI.TimelineTimer
	if tt then
		tt.is_active = false
		if tt.sync_progress then tt.sync_progress() end
	end
end

function M.is_eligible()
	local wr = game_access.word_round()
	if not wr then return false end
	if RunMode.is_classic() then
		return true
	end
	if banked_score() > 0 then
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
	if RunMode.is_classic() or banked_score() > 0 then
		return math.floor(banked_score())
	end
	if Timeline then
		return math.floor(Timeline.seconds_remaining())
	end
	return 0
end

function M.capture_reward(opts)
	opts = opts or {}
	if not M.is_eligible() then return end
	local score = opts.score
	if score == nil then
		score = banked_score()
	else
		score = math.floor(score)
	end
	if RunMode.is_classic() or score > 0 then
		if session.captured_score() ~= nil and not opts.refresh and opts.score == nil then
			return
		end
		session.set_captured_score(math.floor(score))
		freeze_classic_timer()
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
