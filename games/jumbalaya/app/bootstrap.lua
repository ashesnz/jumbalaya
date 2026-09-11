--[[
	Application bootstrap (Phase 7).

	Orchestrates engine classes, domain runtime, store, and presentation facades.
]]

require("app.bootstrap.engine_adapter").install()

return true
