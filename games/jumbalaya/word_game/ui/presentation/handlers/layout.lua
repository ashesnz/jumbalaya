--[[ word_game/ui/presentation/handlers/layout.lua - Layout and background hooks ]]

local LayoutRequest = require("word_game.model.layout.request")

local M = {}

function M.register(Presentation, ctx)
	local backgrounds = ctx.backgrounds
	local Layout = ctx.ui.Layout
	local runtime = ctx.runtime

	Presentation.on("layout_refresh", function()
		LayoutRequest.refresh()
	end)

	Presentation.on("run_backgrounds", function()
		backgrounds.run()
		LayoutRequest.refresh()
	end)

	Presentation.on("stage_backgrounds", function(set, hand_index)
		backgrounds.stage(set, hand_index)
	end)

	Presentation.on("layout_refresh_placement", function()
		if Layout and Layout.refresh_placement_layout then
			Layout.refresh_placement_layout()
		elseif runtime().pattern_row and runtime().pattern_row.apply_screen_position then
			runtime().pattern_row:apply_screen_position()
		end
	end)
end

return M
