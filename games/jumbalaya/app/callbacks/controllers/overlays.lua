--[[ app/controllers/overlays.lua - Phase 4 overlay menu controller ]]

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local ViewHost = require("jumbalaya-engine.panels.view_host")

local game = require("app.runtime").game

local M = {}

--- Title logo + mode buttons only belong on the bare main menu (Classic / Time Run).
local function sync_main_menu_title_visibility()
	local g = game()
	if g.STAGE ~= g.STAGES.MAIN_MENU then return end
	local show = not g.OVERLAY_MENU
	if g.SPLASH_LOGO and g.SPLASH_LOGO.states then
		g.SPLASH_LOGO.states.visible = show
	end
	if g.title_top and g.title_top.states then
		g.title_top.states.visible = show
	end
end

local DEFAULT_SETTINGS_TAB_ID = 'tab_but_Game'

local function sync_trade_marketplace(overlay)
	if overlay and overlay.recalculate then
		overlay:recalculate()
	end
end

local function activate_default_settings_tab()
	local overlay = game().OVERLAY_MENU
	if not overlay then return end
	local shoulders = overlay:find_node_by_id('tab_shoulders')
	if not shoulders then return end

	local default_node = overlay:find_node_by_id(DEFAULT_SETTINGS_TAB_ID)
	if not default_node then
		local first = shoulders.children[1]
		default_node = first and first.children[1]
	end
	if not default_node or not default_node.config or not default_node.config.ref_table then return end

	for _, outer in ipairs(shoulders.children) do
		local inner = outer.children and outer.children[1]
		if inner and inner.config and inner.config.choice then
			local chosen = inner == default_node
			inner.config.chosen = chosen
			if inner.config.ref_table then
				inner.config.ref_table.chosen = chosen
			end
		end
	end
	M.switch_tab(default_node)
end

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
	local tab_contents = game().OVERLAY_MENU:find_node_by_id('tab_contents')
	if tab_contents and tab_contents.config.object and tab_contents.config.object.recalculate then
		tab_contents.config.object:set_scene_parent(tab_contents)
		tab_contents.config.object:align_to_major()
		tab_contents.panel:recalculate()
	end
	sync_trade_marketplace(game().OVERLAY_MENU)
	if game().OVERLAY_MENU:find_node_by_id('tab_shoulders') then
		activate_default_settings_tab()
	end
	sync_main_menu_title_visibility()
end

function M.close_overlay()
	if not game().OVERLAY_MENU then return end
	game().INPUT.locks.frame_set = true
	game().INPUT.locks.frame = true
	game().INPUT:shift_context_layer(-1000)
	game().OVERLAY_MENU:remove()
	game().OVERLAY_MENU = nil
	game().SETTINGS.paused = false
	game():queue_settings_write()
	sync_main_menu_title_visibility()
end

return M
