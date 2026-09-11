--[[
	devtools/registry.lua - Section registry.

	To add a new debug section:
	  1. Create devtools/sections/your_feature.lua (see existing sections).
	  2. Add require line in load_defaults() below.
]]

local M = { _sections = {} }

function M.register(section)
	M._sections[#M._sections + 1] = section
end

function M.all()
	return M._sections
end

function M.load_defaults()
	M._sections = {}
	M.register(require "devtools.sections.view")
	M.register(require "devtools.sections.stage")
	M.register(require "devtools.sections.run")
	M.register(require "devtools.sections.collection")
end

return M
