--[[
	devtools/context.lua - Thin facade over Game for debug section handlers.
]]

--- @class DebugContext
--- @field game Game
local DebugContext = {}
DebugContext.__index = DebugContext

function DebugContext.new(game)
	return setmetatable({ game = game }, DebugContext)
end

function DebugContext:is_run_stage()
	return self.game.STAGE == self.game.STAGES.RUN
end

function DebugContext:room_attach()
	return self.game.ROOM_ATTACH or self.game.ROOM
end

return DebugContext
