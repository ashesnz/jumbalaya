--[[ app/bootstrap/engine_services_boot.lua - Phase 7 engine service context at boot ]]

local Engine = require("jumbalaya-engine")
local presentation_boot = require("app.bootstrap.presentation_boot")
local runtime = require("app.runtime")

local M = {}
local engine_instance = nil

function M.install()
	local store = runtime.store()
	if not store then return nil end
	if engine_instance and engine_instance.store == store then
		presentation_boot.bind_engine_events(engine_instance)
		return engine_instance
	end

	engine_instance = Engine.Context.new({ store = store })
	presentation_boot.bind_engine_events(engine_instance)
	if WORD_GAME and WORD_GAME._bind_engine then
		WORD_GAME._bind_engine(engine_instance)
	end
	return engine_instance
end

return M
