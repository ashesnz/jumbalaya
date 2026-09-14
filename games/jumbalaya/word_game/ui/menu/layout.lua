--[[ word_game/ui/menu/layout.lua - Main menu layout and measurement ]]

local game = require("word_game.ui.util.game_runtime").game
local shell = require("word_game.ui.facade").shell()

local M = {}

local BOTTOM_MARGIN_PX = 12
local TITLE_MENU_GAP_PX = 16
local TITLE_TOP_MARGIN_PX = 8
local TITLE_LOGO_BASE_W = 13
local TITLE_LOGO_MIN_SCALE = 0.7
local STACK_GAP_PX = 20

local function menu_px_to_tiles(px)
	local ts = (game().TILESIZE or 1) * (game().TILESCALE or 1)
	return px / ts
end

function M.main_menu_bottom_offset()
	return -menu_px_to_tiles(BOTTOM_MARGIN_PX)
end

function M.main_menu_logo_scale()
	return 1.1 * (game().debug_splash_size_toggle and 0.8 or 1)
end

function M.main_menu_title_offset_y()
	return -(game().debug_splash_size_toggle and 2 or 1.2)
end

function M.main_menu_logo_ratio()
	local logo_atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.jumbalaya_base
	return logo_atlas and logo_atlas.py and logo_atlas.px
		and logo_atlas.py / logo_atlas.px or (267 / 933)
end

function M.main_menu_logo_dimensions(scale)
	scale = scale or M.main_menu_logo_scale()
	local ratio = M.main_menu_logo_ratio()
	return TITLE_LOGO_BASE_W * scale, TITLE_LOGO_BASE_W * scale * ratio
end

function M.main_menu_title_menu_gap_px()
	return TITLE_MENU_GAP_PX
end

function M.main_menu_menu_top(menu_h)
	local room_h = game().TILE_H or (game().ROOM_ATTACH and game().ROOM_ATTACH.T.h) or 11.5
	return room_h + M.main_menu_bottom_offset() - menu_h
end

local function main_menu_find_button_node(ui, action)
	if not ui or not ui.root_node then return nil end
	local found = nil
	local function walk(node)
		if found or type(node) ~= "table" then return end
		if node.config and node.config.button == action then
			found = node
			return
		end
		if node.children then
			for _, child in ipairs(node.children) do
				walk(child)
			end
		end
	end
	walk(ui.root_node)
	return found
end

function M.main_menu_button_abs_rect(ui, id_or_action)
	if not ui then return nil end
	local node = ui:find_node_by_id(id_or_action)
	if not node then
		node = main_menu_find_button_node(ui, id_or_action)
	end
	if not node or not node.T then return nil end
	local ox, oy = 0, 0
	local parent = node.parent
	while parent do
		if parent.role and parent.role.offset then
			ox = ox + parent.role.offset.x
			oy = oy + parent.role.offset.y
		end
		parent = parent.parent
	end
	local x = node.T.x + ox
	local y = node.T.y + oy
	local w = node.T.w
	return { x = x, y = y, w = w, h = node.T.h, right = x + w }
end

function M.main_menu_mode_utility_edge_alignment(ui, opts)
	opts = opts or {}
	if not ui then return nil end
	if opts.recalculate then ui:recalculate() end
	local classic = M.main_menu_button_abs_rect(ui, "main_menu_classic")
	local time_run = M.main_menu_button_abs_rect(ui, "main_menu_time_run")
	local settings = M.main_menu_button_abs_rect(ui, "open_settings")
	if not classic or not time_run or not settings then return nil end
	return { classic = classic, time_run = time_run, settings = settings }
end

function M.main_menu_mode_utility_column_alignment(ui, opts)
	local edges = M.main_menu_mode_utility_edge_alignment(ui, opts)
	if not edges then return nil end
	return {
		classic = edges.classic.x + edges.classic.w * 0.5,
		time_run = edges.time_run.x + edges.time_run.w * 0.5,
		settings = edges.settings.x + edges.settings.w * 0.5,
	}
end

function M.layout_main_menu_mode_column()
	if not game().MAIN_MENU_UI then return end
	local row = game().MAIN_MENU_UI:find_node_by_id("main_menu_mode_align_row")
	if row and row.role then
		row.role.offset.x = 0
	end
	game().MAIN_MENU_UI:recalculate()
	local settings_rect = M.main_menu_button_abs_rect(game().MAIN_MENU_UI, "open_settings")
	local classic_rect = M.main_menu_button_abs_rect(game().MAIN_MENU_UI, "main_menu_classic")
	if not settings_rect or not classic_rect or not row or not row.role then return end
	local delta = settings_rect.x - classic_rect.x
	if math.abs(delta) < 0.01 then return end
	row.role.offset.x = delta
	if game().MAIN_MENU_UI.root_node and game().MAIN_MENU_UI.root_node.move_with_major then
		game().MAIN_MENU_UI.root_node:move_with_major(0)
	end
end

local function main_menu_child_with_id(node, id)
	if not node then return nil end
	if node.config and node.config.id == id then return node end
	for _, child in ipairs(node.children or {}) do
		local found = main_menu_child_with_id(child, id)
		if found then return found end
	end
	return nil
end

local function main_menu_child_with_action(node, action)
	if not node then return nil end
	if node.config and node.config.button == action then return node end
	for _, child in ipairs(node.children or {}) do
		local found = main_menu_child_with_action(child, action)
		if found then return found end
	end
	return nil
end

local function main_menu_mode_chrome_row(node)
	if not node then return nil end
	if node.config and node.config.no_stretch then return node end
	for _, child in ipairs(node.children or {}) do
		local found = main_menu_mode_chrome_row(child)
		if found then return found end
	end
	return nil
end

function M.main_menu_chrome_widths(ui)
	if not ui or not ui.root_node then return nil end
	ui:recalculate()
	ui.root_node:set_wh()
	local mode_row = main_menu_mode_chrome_row(ui.root_node)
	local settings_btn = main_menu_find_button_node(ui, "open_settings")
	local util_row = settings_btn and settings_btn.parent and settings_btn.parent.parent
	if not mode_row or not util_row then return nil end
	return { mode = mode_row.T.w, util = util_row.T.w }
end

function M.main_menu_stack_gap_tiles(ui)
	if not ui or not ui.root_node then return nil end
	ui:recalculate()
	local outer = ui.root_node.children and ui.root_node.children[1]
	if not outer then return nil end
	local mode_col, util_row = nil, nil
	for _, child in ipairs(outer.children or {}) do
		if main_menu_child_with_id(child, "main_menu_classic") then
			mode_col = child
		elseif main_menu_child_with_action(child, "open_settings") then
			util_row = child
		end
	end
	if not mode_col or not util_row or not mode_col.T or not util_row.T then return nil end
	return util_row.T.y - (mode_col.T.y + mode_col.T.h)
end

function M.main_menu_measure_stacks(ui)
	if not ui then return nil end
	ui:recalculate()
	local function rect(node)
		if not node or not node.T then return nil end
		return { x = node.T.x, y = node.T.y, w = node.T.w, h = node.T.h }
	end
	local classic = ui:find_node_by_id('main_menu_classic')
	local time_run = ui:find_node_by_id('main_menu_time_run')
	local settings = main_menu_find_button_node(ui, 'open_settings')
	return {
		classic = rect(classic),
		time_run = rect(time_run),
		settings = rect(settings),
		menu = ui.T and { x = ui.T.x, y = ui.T.y, w = ui.T.w, h = ui.T.h } or nil,
	}
end

function M.main_menu_resolve_logo_layout(menu_h, gap_tiles)
	menu_h = menu_h or 0
	gap_tiles = gap_tiles or menu_px_to_tiles(TITLE_MENU_GAP_PX)
	local scale = M.main_menu_logo_scale()
	local min_scale = TITLE_LOGO_MIN_SCALE
	local min_y = menu_px_to_tiles(TITLE_TOP_MARGIN_PX)
	local tile_w = game().TILE_W or (game().ROOM_ATTACH and game().ROOM_ATTACH.T.w) or 20

	while scale >= min_scale do
		local logo_w, logo_h = M.main_menu_logo_dimensions(scale)
		local menu_top = M.main_menu_menu_top(menu_h)
		local offset_y = M.main_menu_title_offset_y()
		local default_y = game().TILE_H / 2 - logo_h / 2 + offset_y
		local max_bottom = menu_top - gap_tiles
		local y = math.min(default_y, max_bottom - logo_h)
		y = math.max(y, min_y)
		if y + logo_h + gap_tiles <= menu_top then
			return {
				scale = scale,
				x = tile_w / 2 - logo_w / 2,
				y = y,
				w = logo_w,
				h = logo_h,
				menu_top = menu_top,
				title_bottom = y + logo_h,
				gap = menu_top - (y + logo_h),
			}
		end
		scale = scale - 0.05
	end

	local logo_w, logo_h = M.main_menu_logo_dimensions(min_scale)
	local menu_top = M.main_menu_menu_top(menu_h)
	local y = math.max(min_y, menu_top - gap_tiles - logo_h)
	return {
		scale = min_scale,
		x = tile_w / 2 - logo_w / 2,
		y = y,
		w = logo_w,
		h = logo_h,
		menu_top = menu_top,
		title_bottom = y + logo_h,
		gap = menu_top - (y + logo_h),
	}
end

function M.main_menu_title_rect()
	if game().title_top and game().title_top.T then
		return {
			x = game().title_top.T.x,
			y = game().title_top.T.y,
			w = game().title_top.T.w,
			h = game().title_top.T.h,
		}
	end
	local menu_h = game().MAIN_MENU_UI and game().MAIN_MENU_UI.T and game().MAIN_MENU_UI.T.h or 0
	local layout = M.main_menu_resolve_logo_layout(menu_h)
	return { x = layout.x, y = layout.y, w = layout.w, h = layout.h }
end

function M.main_menu_layout_gap()
	if not game().MAIN_MENU_UI or not game().MAIN_MENU_UI.T then return nil end
	local title = M.main_menu_title_rect()
	if not title then return nil end
	return game().MAIN_MENU_UI.T.y - (title.y + title.h)
end

function M.layout_main_menu_title()
	if not game().title_top then return end

	local menu_h = game().MAIN_MENU_UI and game().MAIN_MENU_UI.T and game().MAIN_MENU_UI.T.h or 0
	local layout = M.main_menu_resolve_logo_layout(menu_h)

	game().title_top.T.x = layout.x
	game().title_top.T.y = layout.y
	game().title_top.T.w = layout.w
	game().title_top.T.h = layout.h
	if game().title_top.hard_set_T then
		game().title_top:hard_set_T(layout.x, layout.y, layout.w, layout.h)
	end
	game().title_top:snap_VT()

	if game().SPLASH_LOGO and game().SPLASH_LOGO.T then
		local cx = game().title_top.T.x + game().title_top.T.w * 0.5
		local cy = game().title_top.T.y + game().title_top.T.h * 0.5
		game().SPLASH_LOGO.T.w = layout.w
		game().SPLASH_LOGO.T.h = layout.h
		if game().SPLASH_LOGO.hard_set_T then
			game().SPLASH_LOGO:hard_set_T(cx - layout.w * 0.5, cy - layout.h * 0.5, layout.w, layout.h)
		end
		if game().SPLASH_LOGO.VT then
			game().SPLASH_LOGO.VT.w = layout.w
			game().SPLASH_LOGO.VT.h = layout.h
		end
		if game().SPLASH_LOGO.align_to_major then
			game().SPLASH_LOGO:align_to_major()
		end
	end
	shell.set_main_menu_logo_applied_scale(layout.scale)
end

function M.layout_main_menu()
	if not game().MAIN_MENU_UI or not game().MAIN_MENU_UI.T then return end
	game().MAIN_MENU_UI.alignment.offset.y = M.main_menu_bottom_offset()
	game().MAIN_MENU_UI:recalculate()
	M.layout_main_menu_mode_column()
	game().MAIN_MENU_UI:align_to_major()
	M.layout_main_menu_title()
end

return M
