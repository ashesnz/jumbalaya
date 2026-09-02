--[[
	word_game/ui/menu.lua - Main menu, profile, and language UI.

	These definitions remain global because the engine UI callbacks use them
	directly.
]]

local Layout = require "word_game.ui.layout"
local Easing = require "app.effects.easing"
local MenuEffects = require "app.effects.menu"
local Scheduler = require "app.effects.scheduler"
local Components = require "word_game.ui.widgets.components"

function G.DEFINITIONS.profile_select()
  G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1

  local t =   build_generic_options({padding = 0,contents ={
      {n=G.UI.ROW, config={align = "cm", padding = 0, draw_layer = 1, minw = 4}, nodes={
        make_tab_strip(
        {tabs = {
            {
                label = 1,
                chosen = G.focused_profile == 1,
                tab_definition_function = G.DEFINITIONS.profile_option,
                tab_definition_function_args = 1
            },
            {
                label = 2,
                chosen = G.focused_profile == 2,
                tab_definition_function = G.DEFINITIONS.profile_option,
                tab_definition_function_args = 2
            },
            {
                label = 3,
                chosen = G.focused_profile == 3,
                tab_definition_function = G.DEFINITIONS.profile_option,
                tab_definition_function_args = 3
            }
        },
        snap_to_nav = true}),
      }},
  }})
  return t
end


function G.DEFINITIONS.profile_option(_profile)
  sync_discover_counts()
  G.focused_profile = _profile
  local packed = read_save_payload(G.focused_profile..'/'..'profile.acs')
  local profile_data = packed and unpack_source(packed) or nil
  if profile_data then
    profile_data.name = profile_data.name or ("P".._profile)
  end
  G.PROFILES[_profile].name = profile_data and profile_data.name or ''

  local lwidth, rwidth, scale = 1, 1, 1
  G.CHECK_PROFILE_DATA = nil
  local t = {n=G.UI.ROOT, config={align = 'cm', colour = G.C.CLEAR}, nodes={
    {n=G.UI.ROW, config={align = 'cm',padding = 0.1, minh = 0.8}, nodes={
        ((_profile == G.SETTINGS.profile) or not profile_data) and {n=G.UI.ROW, config={align = "cm"}, nodes={
        make_text_field({
          w = 4, max_length = 16, prompt_text = localize('term_enter_name'),
          ref_table = G.PROFILES[_profile], ref_value = 'name',extended_corpus = true, keyboard_offset = 1,
          callback = function() 
            G:queue_settings_write()
            G.WRITE_FLAGS.force = true
          end
        }),
      }} or {n=G.UI.ROW, config={align = 'cm',padding = 0.1, minw = 4, r = 0.1, colour = G.C.BLACK, minh = 0.6}, nodes={
        {n=G.UI.TEXT, config={text = G.PROFILES[_profile].name, scale = 0.45, colour = G.C.WHITE}},
      }},
    }},
    {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", minw = 6}, nodes={
        (G.PROFILES[_profile].progress and G.PROFILES[_profile].progress.discovered) and make_progress_box(G.PROFILES[_profile].progress, 0.5) or
        {n=G.UI.COLUMN, config={align = "cm", minh = 4, minw = 5.2, colour = G.C.BLACK, r = 0.1}, nodes={
          {n=G.UI.TEXT, config={text = localize('term_empty_caps'), scale = 0.5, colour = G.C.UI.TRANSPARENT_LIGHT}}
        }},
      }},
      {n=G.UI.COLUMN, config={align = "cm", minh = 4}, nodes={
        {n=G.UI.ROW, config={align = "cm", minh = 1}, nodes={
          profile_data and {n=G.UI.ROW, config={align = "cm"}, nodes={
            {n=G.UI.COLUMN, config={align = "cm", minw = lwidth}, nodes={{n=G.UI.TEXT, config={text = localize('term_wins'),colour = G.C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
            {n=G.UI.COLUMN, config={align = "cm"}, nodes={{n=G.UI.TEXT, config={text = ': ',colour = G.C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
            {n=G.UI.COLUMN, config={align = "cl", minw = rwidth}, nodes={{n=G.UI.TEXT, config={text = tostring(profile_data.career_stats.c_wins),colour = G.C.RED, shadow = true, scale = 1*scale}}}}
          }} or nil,
        }},
        {n=G.UI.ROW, config={align = "cm", padding = 0.2}, nodes={
          {n=G.UI.ROW, config={align = "cm", padding = 0}, nodes={
            {n=G.UI.ROW, config={align = "cm", minw = 4, maxw = 4, minh = 0.8, padding = 0.2, r = 0.1, hover = true, colour = G.C.BLUE,func = 'can_load_profile', button = "load_profile", shadow = true, focus_args = {nav = 'wide'}}, nodes={
              {n=G.UI.TEXT, config={text = _profile == G.SETTINGS.profile and localize('ui_current_profile') or profile_data and localize('ui_load_profile') or localize('ui_create_profile'), ref_value = 'load_button_text', scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}
            }}
          }},
          {n=G.UI.ROW, config={align = "cm", padding = 0, minh = 0.7}, nodes={
            {n=G.UI.ROW, config={align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = G.C.RED,func = 'can_delete_profile', button = "delete_profile", shadow = true, focus_args = {nav = 'wide'}}, nodes={
              {n=G.UI.TEXT, config={text = _profile == G.SETTINGS.profile and localize('ui_reset_profile') or localize('ui_delete_profile'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
            }}
          }},
          (_profile == G.SETTINGS.profile and not G.PROFILES[G.SETTINGS.profile].all_unlocked) and {n=G.UI.ROW, config={align = "cm", padding = 0, minh = 0.7}, nodes={
            {n=G.UI.ROW, config={align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = G.C.ORANGE,func = 'can_unlock_all', button = "unlock_all", shadow = true, focus_args = {nav = 'wide'}}, nodes={
              {n=G.UI.TEXT, config={text = localize('ui_unlock_all'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
            }}
          }} or {n=G.UI.ROW, config={align = "cm", minw = 3, maxw = 4, minh = 0.7}, nodes={
            G.PROFILES[_profile].all_unlocked and ((not G.F_NO_ACHIEVEMENTS) and {n=G.UI.TEXT, config={text = localize(G.F_TROPHIES and 'term_trophies_disabled' or 'term_achievements_disabled'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}} or 
              nil) or nil
          }},
        }},
    }},
    }},
    {n=G.UI.ROW, config={align = "cm", padding = 0}, nodes={
      {n=G.UI.TEXT, config={id = 'warning_text', text = localize('hdr_click_confirm'), scale = 0.4, colour = G.C.CLEAR}}
    }}
  }} 
  return t
end


function build_profile_button()

  local letters = {}
  if G.F_DISP_USERNAME then
    for c in each_utf8_char(G.F_DISP_USERNAME) do
      local leng = G.LANGUAGES['all1'].font.FONT:hasGlyphs(c)
      letters[#letters+1] = {n=G.UI.TEXT, config={lang = G.LANGUAGES[leng and 'all1' or 'all2'],text = c, scale = 0.3, colour = blend_colours(G.C.GREEN, G.C.WHITE, 0.7), shadow = true}}
    end
  end

  if not G.PROFILES[G.SETTINGS.profile].name then 
    G.PROFILES[G.SETTINGS.profile].name = "P"..G.SETTINGS.profile
  end

 return {n=G.UI.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes={
    {n=G.UI.ROW, config={align = "cm", padding = 0.2, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK}, nodes={
      {n=G.UI.ROW, config={align = "cm"}, nodes={
        {n=G.UI.TEXT, config={text = localize('term_profile'), scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
      }},
      {n=G.UI.ROW, config={align = "cm"}, nodes={
        {n=G.UI.COLUMN, config={align = "cm", padding = 0.15, minw = 2, minh = 0.8, maxw = 2, r = 0.1, hover = true, colour = blend_colours(G.C.WHITE, G.C.GREY, 0.2), button = 'profile_select', shadow = true}, nodes={
          {n=G.UI.TEXT, config={ref_table = G.PROFILES[G.SETTINGS.profile], ref_value = 'name', scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
        }},
      }}
    }},
    G.F_DISP_USERNAME and {n=G.UI.ROW, config={align = "cm"}, nodes={
      {n=G.UI.ROW, config={align = "cm"}, nodes={
        {n=G.UI.TEXT, config={text = localize('term_playing_as'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
      }},
      {n=G.UI.ROW, config={align = "cm", minh = 0.12}, nodes={}},
      {n=G.UI.ROW, config={align = "cm", maxw = 2}, nodes=letters}
    }} or nil,
  }}
end


local STACK_GAP_PX = 20
local BOTTOM_MARGIN_PX = 12
local TITLE_MENU_GAP_PX = 16
local TITLE_TOP_MARGIN_PX = 8
local TITLE_LOGO_BASE_W = 13
local TITLE_LOGO_MIN_SCALE = 0.7

local function menu_px_to_tiles(px)
	local ts = (G.TILESIZE or 1) * (G.TILESCALE or 1)
	return px / ts
end

local function menu_button_chrome()
	return {
		align = "cm",
		padding = 0.24,
		r = Components.CHROME.radius,
		colour = G.C.L_BLACK,
		mid = true,
	}
end

local function menu_mode_chrome()
	local chrome = menu_button_chrome()
	chrome.no_stretch = true
	chrome.padding = 0
	return chrome
end

function main_menu_bottom_offset()
	return -menu_px_to_tiles(BOTTOM_MARGIN_PX)
end

function main_menu_logo_scale()
	return 1.1 * (G.debug_splash_size_toggle and 0.8 or 1)
end

function main_menu_title_offset_y()
	return -(G.debug_splash_size_toggle and 2 or 1.2)
end

function main_menu_logo_ratio()
	local logo_atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.jumbalaya_base
	return logo_atlas and logo_atlas.py and logo_atlas.px
		and logo_atlas.py / logo_atlas.px or (267 / 933)
end

function main_menu_logo_dimensions(scale)
	scale = scale or main_menu_logo_scale()
	local ratio = main_menu_logo_ratio()
	return TITLE_LOGO_BASE_W * scale, TITLE_LOGO_BASE_W * scale * ratio
end

function main_menu_title_menu_gap_px()
	return TITLE_MENU_GAP_PX
end

function main_menu_menu_top(menu_h)
	local room_h = G.TILE_H or (G.ROOM_ATTACH and G.ROOM_ATTACH.T.h) or 11.5
	return room_h + main_menu_bottom_offset() - menu_h
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

function main_menu_button_abs_rect(ui, id_or_action)
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

function main_menu_mode_utility_edge_alignment(ui, opts)
	opts = opts or {}
	if not ui then return nil end
	if opts.recalculate then ui:recalculate() end
	local classic = main_menu_button_abs_rect(ui, "main_menu_classic")
	local time_run = main_menu_button_abs_rect(ui, "main_menu_time_run")
	local stats = main_menu_button_abs_rect(ui, "show_high_scores")
	if not classic or not time_run or not stats then return nil end
	return { classic = classic, time_run = time_run, stats = stats }
end

function main_menu_mode_utility_column_alignment(ui, opts)
	local edges = main_menu_mode_utility_edge_alignment(ui, opts)
	if not edges then return nil end
	return {
		classic = edges.classic.x + edges.classic.w * 0.5,
		time_run = edges.time_run.x + edges.time_run.w * 0.5,
		stats = edges.stats.x + edges.stats.w * 0.5,
	}
end

function layout_main_menu_mode_column()
	if not G.MAIN_MENU_UI then return end
	local row = G.MAIN_MENU_UI:find_node_by_id("main_menu_mode_align_row")
	if row and row.role then
		row.role.offset.x = 0
	end
	G.MAIN_MENU_UI:recalculate()
	local stats_rect = main_menu_button_abs_rect(G.MAIN_MENU_UI, "show_high_scores")
	local classic_rect = main_menu_button_abs_rect(G.MAIN_MENU_UI, "main_menu_classic")
	if not stats_rect or not classic_rect or not row or not row.role then return end
	local delta = stats_rect.x - classic_rect.x
	if math.abs(delta) < 0.01 then return end
	row.role.offset.x = delta
	if G.MAIN_MENU_UI.root_node and G.MAIN_MENU_UI.root_node.move_with_major then
		G.MAIN_MENU_UI.root_node:move_with_major(0)
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

function main_menu_chrome_widths(ui)
	if not ui or not ui.root_node then return nil end
	ui:recalculate()
	ui.root_node:set_wh()
	local mode_row = main_menu_mode_chrome_row(ui.root_node)
	local settings_btn = main_menu_find_button_node(ui, "open_settings")
	local util_row = settings_btn and settings_btn.parent and settings_btn.parent.parent
	if not mode_row or not util_row then return nil end
	return { mode = mode_row.T.w, util = util_row.T.w }
end

function main_menu_stack_gap_tiles(ui)
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

function main_menu_measure_stacks(ui)
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

function main_menu_resolve_logo_layout(menu_h, gap_tiles)
	menu_h = menu_h or 0
	gap_tiles = gap_tiles or menu_px_to_tiles(TITLE_MENU_GAP_PX)
	local scale = main_menu_logo_scale()
	local min_scale = TITLE_LOGO_MIN_SCALE
	local min_y = menu_px_to_tiles(TITLE_TOP_MARGIN_PX)
	local tile_w = G.TILE_W or (G.ROOM_ATTACH and G.ROOM_ATTACH.T.w) or 20

	while scale >= min_scale do
		local logo_w, logo_h = main_menu_logo_dimensions(scale)
		local menu_top = main_menu_menu_top(menu_h)
		local offset_y = main_menu_title_offset_y()
		local default_y = G.TILE_H / 2 - logo_h / 2 + offset_y
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

	local logo_w, logo_h = main_menu_logo_dimensions(min_scale)
	local menu_top = main_menu_menu_top(menu_h)
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

function main_menu_title_rect()
	if G.title_top and G.title_top.T then
		return {
			x = G.title_top.T.x,
			y = G.title_top.T.y,
			w = G.title_top.T.w,
			h = G.title_top.T.h,
		}
	end
	local menu_h = G.MAIN_MENU_UI and G.MAIN_MENU_UI.T and G.MAIN_MENU_UI.T.h or 0
	local layout = main_menu_resolve_logo_layout(menu_h)
	return { x = layout.x, y = layout.y, w = layout.w, h = layout.h }
end

function main_menu_layout_gap()
	if not G.MAIN_MENU_UI or not G.MAIN_MENU_UI.T then return nil end
	local title = main_menu_title_rect()
	if not title then return nil end
	return G.MAIN_MENU_UI.T.y - (title.y + title.h)
end

function layout_main_menu_title()
	if not G.title_top then return end

	local menu_h = G.MAIN_MENU_UI and G.MAIN_MENU_UI.T and G.MAIN_MENU_UI.T.h or 0
	local layout = main_menu_resolve_logo_layout(menu_h)

	G.title_top.T.x = layout.x
	G.title_top.T.y = layout.y
	G.title_top.T.w = layout.w
	G.title_top.T.h = layout.h
	if G.title_top.hard_set_T then
		G.title_top:hard_set_T(layout.x, layout.y, layout.w, layout.h)
	end
	G.title_top:snap_VT()

	if G.SPLASH_LOGO and G.SPLASH_LOGO.T then
		local cx = G.title_top.T.x + G.title_top.T.w * 0.5
		local cy = G.title_top.T.y + G.title_top.T.h * 0.5
		G.SPLASH_LOGO.T.w = layout.w
		G.SPLASH_LOGO.T.h = layout.h
		if G.SPLASH_LOGO.hard_set_T then
			G.SPLASH_LOGO:hard_set_T(cx - layout.w * 0.5, cy - layout.h * 0.5, layout.w, layout.h)
		end
		if G.SPLASH_LOGO.VT then
			G.SPLASH_LOGO.VT.w = layout.w
			G.SPLASH_LOGO.VT.h = layout.h
		end
		if G.SPLASH_LOGO.align_to_major then
			G.SPLASH_LOGO:align_to_major()
		end
	end
	G.main_menu_logo_applied_scale = layout.scale
end

function layout_main_menu()
	if not G.MAIN_MENU_UI or not G.MAIN_MENU_UI.T then return end
	G.MAIN_MENU_UI.alignment.offset.y = main_menu_bottom_offset()
	G.MAIN_MENU_UI:recalculate()
	layout_main_menu_mode_column()
	G.MAIN_MENU_UI:align_to_major()
	layout_main_menu_title()
end

function build_main_menu_mode_buttons()
	return build_main_menu_buttons()
end

function build_main_menu_buttons()
	local text_size = 0.58
	local button_w, button_h = 3.4, 1.15
	local gap = 0.22
	local stack_gap = menu_px_to_tiles(STACK_GAP_PX)
	local chrome = menu_button_chrome()

	local function menu_button(id, label, action, colour)
		return Components.button{
			id = id,
			onClick = action,
			colour = colour,
			width = button_w,
			height = button_h,
			label = {label},
			textSize = text_size,
			col = true,
		}
	end

	local function mode_button(id, label, action, colour)
		return { n = G.UI.ROW, config = { align = "cm" }, nodes = {
			menu_button(id, label, action, colour),
		}}
	end

	local function gap_node()
		return {n=G.UI.COLUMN, config={minw = gap}, nodes={}}
	end

	local function mode_stack()
		return {n=G.UI.ROW, config=menu_mode_chrome(), nodes={
			mode_button('main_menu_classic', localize('ui_classic'), 'begin_classic_run', G.C.BLUE),
			{n=G.UI.ROW, config={minh = gap, minw = button_w}, nodes={}},
			mode_button('main_menu_time_run', localize('ui_time_run'), 'begin_time_run', G.C.GREEN),
		}}
	end

	return {
		n=G.UI.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes={
			{n=G.UI.COLUMN, config={align = "cm", padding = 0}, nodes={
				{n=G.UI.ROW, config={
					id = "main_menu_mode_align_row",
					align = "cm",
					padding = 0,
					colour = G.C.CLEAR,
				}, nodes={
					mode_stack(),
				}},
				{n=G.UI.ROW, config={minh = stack_gap}, nodes={}},
				{n=G.UI.ROW, config=chrome, nodes={
					menu_button(nil, localize('ui_settings'), 'open_settings', G.C.ORANGE),
					gap_node(),
					menu_button(nil, localize('ui_stats'), 'show_high_scores', G.C.FILTER),
					gap_node(),
					menu_button(nil, localize('ui_quit_cap'), 'quit', G.C.RED),
				}},
			}},
		}}
end


function G.DEFINITIONS.language_selector()
  local rows = {}
  local langs = {}
  for k, v in pairs(G.LANGUAGES) do
    if not v.omit then 
      langs[#langs+1] = v
    end
  end
  table.sort(langs, (function(a, b) return a.label < b.label end))
  local _row = {}
  for k, v in ipairs(langs) do
    _row[#_row+1] = {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minh = 0.7, minw = 4.5, button = 'change_lang', ref_table = v, colour = G.C.BLUE, hover = true, shadow = true, focus_args = {snap_to = (k == 1)}}, nodes={
      {n=G.UI.ROW, config={align = "cm"}, nodes={
        {n=G.UI.TEXT, config={text = v.label, lang = v, scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
      }}
    }}
    if _row[3] or (k == #langs) then 
      rows[#rows+1] = {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes=_row}
      _row = {}
    end
  end
  
  local discord = Sprite(0,0,0.6,0.6,G.TEXTURE_ATLASES["icons"], {x=2, y=0})
  discord.states.drag.can = false

  local t = build_generic_options({contents ={
    {n=G.UI.ROW, config={align = "cm", padding = 0.05}, nodes=rows},
    {n=G.UI.ROW, config={align = "cm", padding = 0.05}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", padding = 0.1, minw = 4, maxw = 4, r = 0.1, minh = 0.8, colour = blend_colours(G.C.GREEN, G.C.GREY, 0.4)}, nodes={
        {n=G.UI.OBJECT, config={object = discord}},
        {n=G.UI.TEXT, config={text = G.LANG.button, scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
      }},
    }}
  }})
  return t
end

-- Main menu lifecycle and title presentation.

require "word_game.ui.title_logo"

local TITLE_GARDEN_MOSS = {0.12, 0.24, 0.14, 1}

local function setup_title_garden_background()
	if G.SPLASH_BACK then
		G.SPLASH_BACK:remove()
		G.SPLASH_BACK = nil
	end

	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.title_garden
	if not atlas then return end

	G.SPLASH_BACK = Sprite(-30, -13, G.ROOM.T.w + 60, G.ROOM.T.h + 22, atlas, {x = 0, y = 0})
	G.SPLASH_BACK:set_alignment({major = G.ROOM_ATTACH, type = "cm", offset = {x = 0, y = 0}})
	G.SPLASH_BACK:define_draw_steps({{
		shader = "garden_title",
		send = {{name = "time", ref_table = G.TIMERS, ref_value = "REAL"}},
	}})
end

function Game:open_main_menu(change_context)
	if change_context ~= "splash" then
		G.TIMERS.REAL = 12
		G.TIMERS.TOTAL = 12
	else
		retag_audio(G.STATES.MENU)
	end

	self:prep_stage(G.STAGES.MAIN_MENU, G.STATES.MENU, true)
	self.GAME.selected_back = WORD_GAME.Back.new(G.P_CENTERS.deck_alpha)

	if not G.SETTINGS.tutorial_complete and G.SETTINGS.tutorial_progress
		and G.SETTINGS.tutorial_progress.completed_parts
		and G.SETTINGS.tutorial_progress.completed_parts.big_blind then
		G.SETTINGS.tutorial_complete = true
	end
	if G.FUNCS and G.FUNCS.change_shadows and G.SETTINGS and G.SETTINGS.GRAPHICS then
		G.FUNCS.change_shadows{to_key = G.SETTINGS.GRAPHICS.shadows == "On" and 1 or 2}
	end
	Easing.background_colour{new_colour = TITLE_GARDEN_MOSS, contrast = 1}
	if G.SPLASH_FRONT then G.SPLASH_FRONT:remove(); G.SPLASH_FRONT = nil end
	setup_title_garden_background()

	Scheduler.add{mode = "instant", func = function()
		return true
	end}

	local scale = 1.1 * (G.debug_splash_size_toggle and 0.8 or 1)
	self.title_top = CardArea(0, 0, G.CARD_W, G.CARD_H, {card_limit = 1, type = "title"})
	local logo_atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.jumbalaya_base
	local logo_ratio = logo_atlas and logo_atlas.py and logo_atlas.px
		and logo_atlas.py / logo_atlas.px or (267 / 933)
	local logo_w, logo_h = 13 * scale, 13 * scale * logo_ratio
	if logo_atlas and G.TEXTURE_ATLASES.jumbalaya_start_a and G.TEXTURE_ATLASES.jumbalaya_end_a then
		G.SPLASH_LOGO = TitleLogo.create(self.title_top, logo_w, logo_h)
	else
		G.SPLASH_LOGO = Sprite(0, 0, logo_w, logo_h, logo_atlas, {x = 0, y = 0})
		G.SPLASH_LOGO:set_alignment({major = self.title_top, type = "cm", bond = "Strong", offset = {x = 0, y = 0}})
		G.SPLASH_LOGO:define_draw_steps({{shader = "dissolve"}})
	end
	G.SPLASH_LOGO.dissolve_colours = {G.C.WHITE, G.C.WHITE}
	G.SPLASH_LOGO.dissolve = 1

	Scheduler.add{mode = "delayed",
		delay = change_context == "splash" and 1.8 or change_context == "game" and 2 or 0.15,
		blockable = false, blocking = false, func = function()
		local crumple_variant = change_context == "splash" and 2 or 3
		if play_sfx then
			play_sfx("magic_crumple" .. crumple_variant, change_context == "splash" and 0.95 or 1.25, 0.85)
			play_sfx("whoosh1", 0.55, 0.7)
		end
			if G.SPLASH_LOGO then Easing.value{ref_table = G.SPLASH_LOGO, ref_value = "dissolve", mod = -1, delay = change_context == "splash" and 2.3 or 0.9} end
			if G.VIBRATION then G.VIBRATION = G.VIBRATION + 1.5 end
			return true
		end}
	Scheduler.delayed{delay = 0.1 + (change_context == "splash" and 2 or change_context == "game" and 1.5 or 0)}
	Scheduler.add{func = function() if G.INPUT then G.INPUT.lock_input = false end; return true end}
	Layout.set_screen_positions()
	self.title_top:sort("order")
	self.title_top:set_ranks()
	self.title_top:relayout()
	self.title_top:hard_set_cards()
	Scheduler.add{mode = "delayed", delay = change_context == "splash" and 4.05 or change_context == "game" and 3 or 0.4,
		blockable = false, blocking = false, func = function()
			MenuEffects.set_main_ui()
			return true
		end}
	Scheduler.add{blockable = false, func = function()
		if sync_discover_counts then sync_discover_counts() end
		if set_profile_progress then set_profile_progress() end
		G.REFRESH_ALERTS = true
		return true
	end}
	LayoutView{definition = {n = G.UI.ROOT, config = {align = "cm", colour = G.C.UI.TRANSPARENT_DARK}, nodes = {
		{n = G.UI.TEXT, config = {text = G.VERSION, scale = 0.3, colour = G.C.UI.TEXT_LIGHT}},
	}}, config = {align = "tri", offset = {x = 0, y = 0}, major = G.ROOM_ATTACH, bond = "Weak"}}
end


