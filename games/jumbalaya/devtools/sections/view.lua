--[[ devtools/sections/view.lua - Visual debug overlays. ]]

local layout = require "devtools.layout"
local game_runtime = require "devtools.runtime"

local function shell()
	return game_runtime.game()
end

local function bbox_label()
	local game = shell()
	return game and game.DEBUG and "ON" or "OFF"
end

local function atlas_label()
	local game = shell()
	return game and game.F_ATLAS_DEBUG_OVERLAY and "ON" or "OFF"
end

return {
	id = "view",
	order = 5,

	register = function(panel)
		panel.state.bbox_status = bbox_label()
		panel.state.atlas_status = atlas_label()
		panel:action("toggle_bboxes", function()
			local game = shell()
			if game then game.DEBUG = not game.DEBUG end
			panel:set_label("bbox_status", bbox_label())
		end)
		panel:action("toggle_atlas_debug", function()
			local game = shell()
			if game then game.F_ATLAS_DEBUG_OVERLAY = not game.F_ATLAS_DEBUG_OVERLAY end
			panel:set_label("atlas_status", atlas_label())
		end)
	end,

	build = function(panel)
		local rows = {
			layout.labeled_row("bbox_status", panel.state, 0.28),
			layout.labeled_row("atlas_status", panel.state, 0.28),
		}
		for _, row in ipairs(layout.button_columns({
			{ label = "Bounding Boxes", action = "toggle_bboxes" },
			{ label = "Atlas Debug", action = "toggle_atlas_debug" },
		})) do
			rows[#rows + 1] = row
		end
		return layout.section("View", rows)
	end,
}
