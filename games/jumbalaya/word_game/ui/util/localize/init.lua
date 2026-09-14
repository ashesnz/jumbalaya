--[[
	word_game/ui/util/localize/init.lua - Localization facade.

	parse.lua   - markup parser + UTF-8 helpers
	catalog.lua - parse language tables once at boot (init_localization)
	lookup.lua  - resolve parsed blobs into UI copy (localize)
]]

local catalog = require("word_game.ui.util.localize.catalog")
local lookup = require("word_game.ui.util.localize.lookup")
local parse = require("word_game.ui.util.localize.parse")

local M = {}

M.init_localization = catalog.init_localization
M.localize = lookup.localize
M.each_utf8_char = parse.each_utf8_char
M.parse_string = parse.parse_string

return M
