--[[ word_game/ui/menu/definition.lua - Main menu UI definitions ]]

local Components = require("word_game.ui.widgets.components")

local M = {}

local STACK_GAP_PX = 20

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


function M.build_profile_button()

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

function M.build_main_menu_mode_buttons()
	return M.build_main_menu_buttons()
end

function M.build_main_menu_buttons()
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

return M
