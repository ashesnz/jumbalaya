--[[ jumbalaya-engine/session/draw_passes.lua - ordered draw-pass hook registry ]]

local M = {}

local phases = {
	board = {},
	menu = {},
	chrome = {},
	present = {},
}

local sequence = 0

function M.register(phase, name, fn)
	assert(phases[phase], "unknown draw phase: " .. tostring(phase))
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

function M.run(phase, game)
	for _, entry in ipairs(phases[phase]) do
		entry.fn(game)
	end
end

return M
