--[[ app/bootstrap/engine_services_boot.lua - Phase 7 engine service context at boot ]]

local Engine = require("jumbalaya-engine")
local event_bridge = require("bridge.event_bridge")
local runtime = require("bridge.runtime")

local M = {}
local engine_instance = nil

function M.install()
	local store = runtime.store()
	if not store then return nil end
	if engine_instance and engine_instance.store == store then
		event_bridge.install(engine_instance)
		return engine_instance
	end

	engine_instance = Engine.Context.new({ store = store })
	event_bridge.install(engine_instance)
	if WORD_GAME and WORD_GAME._bind_engine then
		WORD_GAME._bind_engine(engine_instance)
	end
	return engine_instance
end

return M
