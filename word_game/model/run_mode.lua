--[[ word_game/model/run_mode.lua - Classic vs Time Run mode helpers ]]

local M = {}

local DEFAULT = "time_run"

local function is_valid(mode)
	return mode == "classic" or mode == "time_run"
end

function M.preferred()
	local mode = G.SETTINGS and G.SETTINGS.preferred_run_mode
	if is_valid(mode) then
		return mode
	end
	return DEFAULT
end

function M.set_preferred(mode)
	if not is_valid(mode) then return end
	G.SETTINGS = G.SETTINGS or {}
	G.SETTINGS.preferred_run_mode = mode
	if G.queue_settings_write then
		G:queue_settings_write()
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
	if G.GAME then
		return G.GAME.run_mode or DEFAULT
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

return M
