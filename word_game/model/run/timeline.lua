--[[ word_game/model/run/timeline.lua - Timeline state mirrored on G.GAME (domain reads) ]]

local Presentation = require("word_game.model.presentation")
local round_config = require("word_game.config.gameplay.round")

local M = {}

local TOTAL = round_config.TIMELINE_SECONDS or 60

local function game()
	return G and G.GAME
end

function M.seconds_remaining()
	local g = game()
	if not g then return math.huge end
	if g.timeline_seconds ~= nil then
		return g.timeline_seconds
	end
	local j = g.word_round and g.word_round.jumble
	return j and j.time_left or math.huge
end

function M.classic_goal_reached()
	local g = game()
	return g and g.timeline_goal_reached == true or false
end

function M.classic_progress_target()
	local g = game()
	local wr = g and g.word_round
	if wr and wr.target then
		return math.max(1, math.floor(wr.target))
	end
	if g and g.timeline_progress_target then
		return math.max(1, math.floor(g.timeline_progress_target))
	end
	return 1
end

function M.add_seconds(seconds)
	if not seconds or seconds == 0 then return end
	local g = game()
	if not g then return end
	local cur = M.seconds_remaining()
	if cur == math.huge then return end
	g.timeline_seconds = math.max(0, math.min(TOTAL, cur + seconds))
	Presentation.emit("timeline_apply_seconds", seconds)
end

return M
