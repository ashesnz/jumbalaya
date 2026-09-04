--[[ word_game/model/perks/timer.lua - Per-hand puzzle deadline (disabled until perks wire it).

	Separate from the vault timeline fuse (`ui/perks/timeline_timer`). Timer perks
	(time_bank, speed_demon, etc.) will hook here when gameplay effects land.
]]

local M = {}

M.ENABLED = false
M.SECONDS = 30

function M.initial_state()
	if not M.ENABLED then
		return { deadline = nil, time_left = nil }
	end
	local now = G and G.TIMERS and G.TIMERS.REAL or 0
	return {
		deadline = now + M.SECONDS,
		time_left = M.SECONDS,
	}
end

function M.time_left(jumble)
	if not M.ENABLED then return math.huge end
	if not jumble or not jumble.deadline then return 0 end
	return math.max(0, jumble.deadline - (G.TIMERS.REAL or 0))
end

--- Returns true when the hand timer has expired.
function M.update(jumble)
	if not M.ENABLED then return false end
	if not jumble then return false end
	jumble.time_left = math.ceil(M.time_left(jumble))
	return jumble.time_left <= 0
end

return M
