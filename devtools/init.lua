--[[
	devtools package - Tab-key developer tools panel.

	Layout (mirrors domain package pattern):
	  init.lua, panel.lua, context.lua, layout.lua, registry.lua  → framework
	  sections/*.lua                                                → feature plugins

	Public API (require "devtools"):
	  DebugPanel       session controller — attach to Game as game.debug_panel
	  register_section add a custom section (see devtools/registry.lua)
	  layout           UI layout helpers

	Note: folder cannot be named "debug" — that conflicts with Lua's
	built-in debug library returned by require("debug").

	Adding a feature section:
	  1. Create devtools/sections/my_feature.lua  (id, order, register, build)
	  2. Register it in devtools/registry.lua → load_defaults()
]]

local registry = require "devtools.registry"

return {
	DebugPanel = require "devtools.panel",
	DebugButton = require "devtools.debug_button",
	register_section = registry.register,
	layout = require "devtools.layout",
}
