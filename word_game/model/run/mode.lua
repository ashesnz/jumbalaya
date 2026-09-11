--[[ word_game/model/run/mode.lua - Classic vs Time Run mode helpers ]]

local live_game = require("word_game.model.live_game")

local Timeline = require("word_game.model.run.timeline")
local game_access = require("word_game.model.game_access")

local M = {}

local DEFAULT = "time_run"

local function is_valid(mode)
	return mode == "classic" or mode == "time_run"
end

function M.preferred()
	local mode = live_game().SETTINGS and live_game().SETTINGS.preferred_run_mode
	if is_valid(mode) then
		return mode
	end
	return DEFAULT
end

function M.set_preferred(mode)
	if not is_valid(mode) then return end
	live_game().SETTINGS = live_game().SETTINGS or {}
	live_game().SETTINGS.preferred_run_mode = mode
	if live_game().queue_settings_write then
		live_game():queue_settings_write()
	end
end

--- Mode for a fresh run: explicit menu choice wins, otherwise last preferred mode.
function M.resolve_for_new_run(explicit)
	if is_valid(explicit) then
		return explicit
	end
	return M.preferred()
end

function M.current()
	local game = game_access.get()
	if game then
		return game.run_mode or DEFAULT
	end
	return M.preferred()
end

function M.is_classic()
	return M.current() == "classic"
end

function M.is_time_run()
	return not M.is_classic()
end

--- Classic lets the player keep scoring on the same puzzle after the target is met.
function M.ends_hand_on_target()
	return not M.is_classic()
end

function M.classic_stage_complete()
	if not M.is_classic() then return false end
	return Timeline.classic_goal_reached()
end

function M.classic_stage_target()
	return Timeline.classic_progress_target()
end

function M.classic_proceed_message()
	return string.format(
		"Target %d Reached! Click Next to Continue.",
		M.classic_stage_target()
	)
end

return M
