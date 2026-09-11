--[[
	word_game/model/run/timeline.lua - Time Run fuse (classic goal mirror).

	Core: jumbalaya_core.config.gameplay.round (targets)
	Store: timeline_seconds, timeline_duration, timeline_active, timeline_goal_reached, …
	Presentation: timeline_tick, timeline_goal_reached, timeline_reset
]]

local Presentation = require("word_game.model.presentation")
local round_config = require("jumbalaya_core.config.gameplay.round")
local game_access = require("word_game.model.game_access")

local M = {}

local DEFAULT_DURATION = round_config.TIMELINE_SECONDS or 60

local function fuse_mode(g)
	if not g then return false end
	if g.timeline_boss_override then return true end
	return (g.run_mode or "time_run") ~= "classic"
end

function M.seconds_remaining()
	local g = game_access.get()
	if not g or not fuse_mode(g) then return math.huge end
	if g.timeline_seconds ~= nil then
		return g.timeline_seconds
	end
	return math.huge
end

function M.duration()
	local g = game_access.get()
	return g and (g.timeline_duration or DEFAULT_DURATION) or DEFAULT_DURATION
end

function M.tick_enabled()
	local g = game_access.get()
	if not g or not fuse_mode(g) then return false end
	if g.timeline_frozen then return false end
	if g.timeline_active == false then return false end
	return g.timeline_seconds ~= nil
end

function M.update(dt)
	if not dt or dt <= 0 then return end
	if not M.tick_enabled() then return end
	game_access.mutate(function(g)
		g.timeline_seconds = math.max(0, g.timeline_seconds - dt)
	end)
end

function M.reset(seconds)
	seconds = seconds or DEFAULT_DURATION
	game_access.mutate(function(g)
		g.timeline_duration = seconds
		g.timeline_seconds = seconds
		g.timeline_active = true
		g.timeline_frozen = false
		g.timeline_boss_override = nil
	end)
	Presentation.emit("timeline_sync_from_model")
end

function M.pause()
	game_access.mutate(function(g)
		g.timeline_active = false
	end)
end

function M.resume()
	game_access.mutate(function(g)
		g.timeline_frozen = false
		g.timeline_active = true
	end)
end

function M.arm_boss(seconds)
	seconds = seconds or DEFAULT_DURATION
	game_access.mutate(function(g)
		g.timeline_duration = seconds
		g.timeline_seconds = seconds
		g.timeline_active = false
		g.timeline_frozen = false
		g.timeline_boss_override = true
	end)
	Presentation.emit("timeline_sync_from_model")
end

function M.clear_boss_override()
	game_access.mutate(function(g)
		g.timeline_boss_override = nil
	end)
end

function M.freeze(seconds)
	game_access.mutate(function(g)
		g.timeline_frozen = true
		g.timeline_active = false
		if seconds ~= nil then
			g.timeline_seconds = math.max(0, seconds)
		end
	end)
end

function M.add_seconds(seconds)
	if not seconds or seconds == 0 then return end
	local g = game_access.get()
	if not g or not fuse_mode(g) then return end
	local cur = M.seconds_remaining()
	if cur == math.huge then return end
	local cap = M.duration()
	game_access.mutate(function(game)
		game.timeline_seconds = math.max(0, math.min(cap, cur + seconds))
	end)
	Presentation.emit("timeline_sync_from_model")
end

function M.classic_goal_reached()
	local g = game_access.get()
	return g and g.timeline_goal_reached == true or false
end

function M.classic_progress_target()
	local g = game_access.get()
	local wr = g and g.word_round
	if wr and wr.target then
		return math.max(1, math.floor(wr.target))
	end
	if g and g.timeline_progress_target then
		return math.max(1, math.floor(g.timeline_progress_target))
	end
	return 1
end

return M
