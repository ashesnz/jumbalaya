--[[ app/controllers/overlays.lua - Phase 4 overlay menu controller ]]

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local ViewHost = require("jumbalaya-engine.panels.view_host")

local game = require("app.runtime").game

local M = {}

function M.switch_tab(e)
	if not e then return end
	clear_overlay_infotip()

	local tab_contents = e.panel:find_node_by_id('tab_contents')
	tab_contents.config.object:remove()
	tab_contents.config.object = ViewHost.create{
		definition = e.config.ref_table.tab_definition_function(e.config.ref_table.tab_definition_function_args),
		config = { offset = { x = 0, y = 0 }, parent = tab_contents, type = 'cm' }
	}
	tab_contents.panel:recalculate()
end

function M.show_overlay(args)
	if not args then return end
	if game().OVERLAY_MENU then game().OVERLAY_MENU:remove() end
	game().INPUT.locks.frame_set = true
	game().INPUT.locks.frame = true
	game().INPUT.press_state.target = nil
	game().INPUT:shift_context_layer(game().NO_MOD_CURSOR_STACK and 0 or 1)

	args.config = args.config or {}
	local stable_overlay = args.config.no_jiggle == true
	args.config = {
		align = args.config.align or "cm",
		offset = args.config.offset or (stable_overlay and { x = 0, y = 0 } or { x = 0, y = 10 }),
		major = args.config.major or game().ROOM_ATTACH,
		bond = 'Weak',
		no_esc = args.config.no_esc,
		no_jiggle = args.config.no_jiggle,
	}
	game().OVERLAY_MENU = true
	game().OVERLAY_MENU = ViewHost.create{
		definition = args.definition,
		config = args.config
	}

	game().OVERLAY_MENU.alignment.offset.y = stable_overlay and (args.config.offset.y or 0) or 0
	if game().ROOM and not stable_overlay then game().ROOM.jiggle = (game().ROOM.jiggle or 0) + 1 end
	game().OVERLAY_MENU:align_to_major()
	if stable_overlay then
		game().OVERLAY_MENU.NEW_ALIGNMENT = false
		game().OVERLAY_MENU.VT.x = game().OVERLAY_MENU.T.x
		game().OVERLAY_MENU.VT.y = game().OVERLAY_MENU.T.y
		game().OVERLAY_MENU.VT.w = game().OVERLAY_MENU.T.w
		game().OVERLAY_MENU.VT.h = game().OVERLAY_MENU.T.h
	end
end

function M.close_overlay()
	if not game().OVERLAY_MENU then return end
	local ok, components = pcall(require, "word_game.ui.widgets.components")
	if ok and components and components.clear_dynamic_actions then
		components.clear_dynamic_actions()
	end
	game().INPUT.locks.frame_set = true
	game().INPUT.locks.frame = true
	game().INPUT:shift_context_layer(-1000)
	game().OVERLAY_MENU:remove()
	game().OVERLAY_MENU = nil
	game().VIEWING_DECK = nil
	game().SETTINGS.paused = false
	game():queue_settings_write()
end

return M
