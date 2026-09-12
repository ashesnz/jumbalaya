--[[
	jumbalaya-engine/session/updaters.lua - ordered per-frame hook registry.

	Subsystems register named updaters per phase instead of hard-coding Game:update.
]]

local M = {}

local phases = {
	early_frame = {},
	early_board = {},
	late_board = {},
	post_input = {},
}

local sequence = 0

function M.register(phase, name, fn)
	assert(phases[phase], "unknown updater phase: " .. tostring(phase))
	M.unregister(phase, name)
	sequence = sequence + 1
	table.insert(phases[phase], {name = name, fn = fn, order = sequence})
	table.sort(phases[phase], function(a, b) return a.order < b.order end)
end

function M.unregister(phase, name)
	local list = phases[phase]
	if not list then return false end
	for i, entry in ipairs(list) do
		if entry.name == name then
			table.remove(list, i)
			return true
		end
	end
	return false
end

function M.run(phase, game, dt)
	for _, entry in ipairs(phases[phase]) do
		entry.fn(game, dt)
	end
end

return M
