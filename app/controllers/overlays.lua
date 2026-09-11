--[[ app/controllers/overlays.lua - Phase 4 overlay menu controller ]]

local Scheduler = require "app.effects.timeline_scheduler"
local ViewHost = require("jumbalaya-engine.view_host")

local BridgeRuntime = require("bridge.runtime")
local function g() return BridgeRuntime.game() end

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
	if g().OVERLAY_MENU then g().OVERLAY_MENU:remove() end
	g().INPUT.locks.frame_set = true
	g().INPUT.locks.frame = true
	g().INPUT.press_state.target = nil
	g().INPUT:shift_context_layer(g().NO_MOD_CURSOR_STACK and 0 or 1)

	args.config = args.config or {}
	local stable_overlay = args.config.no_jiggle == true
	args.config = {
		align = args.config.align or "cm",
		offset = args.config.offset or (stable_overlay and { x = 0, y = 0 } or { x = 0, y = 10 }),
		major = args.config.major or g().ROOM_ATTACH,
		bond = 'Weak',
		no_esc = args.config.no_esc,
		no_jiggle = args.config.no_jiggle,
	}
	g().OVERLAY_MENU = true
	g().OVERLAY_MENU = ViewHost.create{
		definition = args.definition,
		config = args.config
	}

	g().OVERLAY_MENU.alignment.offset.y = stable_overlay and (args.config.offset.y or 0) or 0
	if g().ROOM and not stable_overlay then g().ROOM.jiggle = (g().ROOM.jiggle or 0) + 1 end
	g().OVERLAY_MENU:align_to_major()
	if stable_overlay then
		g().OVERLAY_MENU.NEW_ALIGNMENT = false
		g().OVERLAY_MENU.VT.x = g().OVERLAY_MENU.T.x
		g().OVERLAY_MENU.VT.y = g().OVERLAY_MENU.T.y
		g().OVERLAY_MENU.VT.w = g().OVERLAY_MENU.T.w
		g().OVERLAY_MENU.VT.h = g().OVERLAY_MENU.T.h
	end
end

function M.close_overlay()
	if not g().OVERLAY_MENU then return end
	local ok, components = pcall(require, "word_game.ui.widgets.components")
	if ok and components and components.clear_dynamic_actions then
		components.clear_dynamic_actions()
	end
	g().INPUT.locks.frame_set = true
	g().INPUT.locks.frame = true
	g().INPUT:shift_context_layer(-1000)
	g().OVERLAY_MENU:remove()
	g().OVERLAY_MENU = nil
	g().VIEWING_DECK = nil
	g().SETTINGS.paused = false
	g():queue_settings_write()
end

return M
