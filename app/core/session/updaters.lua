--[[
	app/updaters.lua - ordered per-frame hook registry.

	Subsystems that need a tick every frame register here instead of being
	hard-coded into Game:update. Entries are named (so re-registering replaces)
	and run in registration order within their phase.

	Phases mirror the engine loop's structure so existing ordering is kept:
	  early_board : after the event manager, before animation/move passes
	                (board-state UI coordination, layout flushes, timers)
	  late_board  : after the moveable move pass, before moveable updates
	                (visual stabilization that must see final positions)
	  post_input  : after the input controller update, on real (unscaled) dt
	                (hold-to-act gestures, inspection)

	Register from bootstrap (app/bootstrap/game_boot.lua); guards (e.g. only
	while TABLE_BOARD is active) belong inside the registered function.
]]

local M = {}

local phases = {
	early_board = {},
	late_board = {},
	post_input = {},
}

local sequence = 0

--- Registers (or replaces) a named updater in a phase.
---@param phase string 'early_board'|'late_board'|'post_input'
---@param name string unique key for later unregistration
---@param fn fun(game: table, dt: number)
function M.register(phase, name, fn)
	assert(phases[phase], "unknown updater phase: " .. tostring(phase))
	M.unregister(phase, name)
	sequence = sequence + 1
	table.insert(phases[phase], {name = name, fn = fn, order = sequence})
	table.sort(phases[phase], function(a, b) return a.order < b.order end)
end

--- Removes a previously registered updater. Returns true if found.
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

--- Ticks every updater in a phase, in registration order.
function M.run(phase, game, dt)
	for _, entry in ipairs(phases[phase]) do
		entry.fn(game, dt)
	end
end

return M
