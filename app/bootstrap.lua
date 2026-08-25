--[[
	Application bootstrap.

	Loads legacy global modules in dependency order. Keep this list centralized:
	the runtime classes extend one another at module load time, and the UI/domain
	modules attach functions to globals created by the runtime and game packages.
]]

require "app.bootstrap.engine_boot"
require "app.bootstrap.game_boot"

return true
