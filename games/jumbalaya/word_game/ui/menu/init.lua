--[[ word_game/ui/menu/init.lua - Main menu, profile, and language UI ]]

local definition = require("word_game.ui.menu.definition")
local layout = require("word_game.ui.menu.layout")
local animate = require("word_game.ui.menu.animate")

-- Definition builders (global for engine UI callbacks).
build_profile_button = definition.build_profile_button
build_main_menu_buttons = definition.build_main_menu_buttons
build_main_menu_mode_buttons = definition.build_main_menu_mode_buttons

-- Layout helpers used elsewhere in the codebase.
main_menu_bottom_offset = layout.main_menu_bottom_offset
main_menu_logo_scale = layout.main_menu_logo_scale
main_menu_title_offset_y = layout.main_menu_title_offset_y
main_menu_logo_ratio = layout.main_menu_logo_ratio
main_menu_logo_dimensions = layout.main_menu_logo_dimensions
main_menu_title_menu_gap_px = layout.main_menu_title_menu_gap_px
main_menu_menu_top = layout.main_menu_menu_top
main_menu_button_abs_rect = layout.main_menu_button_abs_rect
main_menu_mode_utility_edge_alignment = layout.main_menu_mode_utility_edge_alignment
main_menu_mode_utility_column_alignment = layout.main_menu_mode_utility_column_alignment
layout_main_menu_mode_column = layout.layout_main_menu_mode_column
main_menu_chrome_widths = layout.main_menu_chrome_widths
main_menu_stack_gap_tiles = layout.main_menu_stack_gap_tiles
main_menu_measure_stacks = layout.main_menu_measure_stacks
main_menu_resolve_logo_layout = layout.main_menu_resolve_logo_layout
main_menu_title_rect = layout.main_menu_title_rect
main_menu_layout_gap = layout.main_menu_layout_gap
layout_main_menu_title = layout.layout_main_menu_title
layout_main_menu = layout.layout_main_menu

-- Title garden animation.
title_garden_sprite_dims = animate.title_garden_sprite_dims
title_garden_pan_offset = animate.title_garden_pan_offset
update_title_garden_pan = animate.update_title_garden_pan

function Game:open_main_menu(change_context)
	return animate.open_main_menu(self, change_context)
end

return {
	definition = definition,
	layout = layout,
	animate = animate,
}
