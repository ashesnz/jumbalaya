--[[ word_game/model/run_mode.lua - Classic vs Time Run mode helpers ]]

local M = {}

function M.current()
	return G.GAME and G.GAME.run_mode or "time_run"
end

function M.is_classic()
	return M.current() == "classic"
end

function M.is_time_run()
	return not M.is_classic()
end

return M
