--[[ word_game/ui/menu/definition.lua - Main menu UI definitions ]]

local game = require("word_game.ui.util.game_runtime").game

local Components = require("word_game.ui.widgets.components")
local Colour = require("jumbalaya-engine.util.colour")

local DEFINITIONS = game().DEFINITIONS

local M = {}

local STACK_GAP_PX = 20

local function menu_px_to_tiles(px)
	local ts = (game().TILESIZE or 1) * (game().TILESCALE or 1)
	return px / ts
end

local function menu_button_chrome()
	return {
		align = "cm",
		padding = 0.24,
		r = Components.CHROME.radius,
		colour = game().C.L_BLACK,
		mid = true,
	}
end

local function menu_mode_chrome()
	local chrome = menu_button_chrome()
	chrome.no_stretch = true
	chrome.padding = 0
	return chrome
end

function DEFINITIONS.profile_select()
  game().focused_profile = game().focused_profile or game().SETTINGS.profile or 1

  local t =   build_generic_options({padding = 0,contents ={
      {n=game().UI.ROW, config={align = "cm", padding = 0, draw_layer = 1, minw = 4}, nodes={
        make_tab_strip(
        {tabs = {
            {
                label = 1,
                chosen = game().focused_profile == 1,
                tab_definition_function = DEFINITIONS.profile_option,
                tab_definition_function_args = 1
            },
            {
                label = 2,
                chosen = game().focused_profile == 2,
                tab_definition_function = DEFINITIONS.profile_option,
                tab_definition_function_args = 2
            },
            {
                label = 3,
                chosen = game().focused_profile == 3,
                tab_definition_function = DEFINITIONS.profile_option,
                tab_definition_function_args = 3
            }
        },
        snap_to_nav = true}),
      }},
  }})
  return t
end


function DEFINITIONS.profile_option(_profile)
  game().focused_profile = _profile
  local packed = read_save_payload(game().focused_profile..'/'..'profile.acs')
  local profile_data = packed and unpack_source(packed) or nil
  if profile_data then
    profile_data.name = profile_data.name or ("P".._profile)
  end
  game().PROFILES[_profile].name = profile_data and profile_data.name or ''

  local lwidth, rwidth, scale = 1, 1, 1
  game().CHECK_PROFILE_DATA = nil
  local t = {n=game().UI.ROOT, config={align = 'cm', colour = game().C.CLEAR}, nodes={
    {n=game().UI.ROW, config={align = 'cm',padding = 0.1, minh = 0.8}, nodes={
        ((_profile == game().SETTINGS.profile) or not profile_data) and {n=game().UI.ROW, config={align = "cm"}, nodes={
        make_text_field({
          w = 4, max_length = 16, prompt_text = localize('term_enter_name'),
          ref_table = game().PROFILES[_profile], ref_value = 'name',extended_corpus = true, keyboard_offset = 1,
          callback = function() 
            game():queue_settings_write()
            game().WRITE_FLAGS.force = true
          end
        }),
      }} or {n=game().UI.ROW, config={align = 'cm',padding = 0.1, minw = 4, r = 0.1, colour = game().C.BLACK, minh = 0.6}, nodes={
        {n=game().UI.TEXT, config={text = game().PROFILES[_profile].name, scale = 0.45, colour = game().C.WHITE}},
      }},
    }},
    {n=game().UI.ROW, config={align = "cm", padding = 0.1}, nodes={
      {n=game().UI.COLUMN, config={align = "cm", minw = 6}, nodes={
        {n=game().UI.COLUMN, config={align = "cm", minh = 4, minw = 5.2, colour = game().C.BLACK, r = 0.1}, nodes={
          {n=game().UI.TEXT, config={text = localize('term_empty_caps'), scale = 0.5, colour = game().C.UI.TRANSPARENT_LIGHT}}
        }},
      }},
      {n=game().UI.COLUMN, config={align = "cm", minh = 4}, nodes={
        {n=game().UI.ROW, config={align = "cm", minh = 1}, nodes={
          profile_data and {n=game().UI.ROW, config={align = "cm"}, nodes={
            {n=game().UI.COLUMN, config={align = "cm", minw = lwidth}, nodes={{n=game().UI.TEXT, config={text = localize('term_wins'),colour = game().C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
            {n=game().UI.COLUMN, config={align = "cm"}, nodes={{n=game().UI.TEXT, config={text = ': ',colour = game().C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
            {n=game().UI.COLUMN, config={align = "cl", minw = rwidth}, nodes={{n=game().UI.TEXT, config={text = tostring(profile_data.career_stats.c_wins),colour = game().C.RED, shadow = true, scale = 1*scale}}}}
          }} or nil,
        }},
        {n=game().UI.ROW, config={align = "cm", padding = 0.2}, nodes={
          {n=game().UI.ROW, config={align = "cm", padding = 0}, nodes={
            {n=game().UI.ROW, config={align = "cm", minw = 4, maxw = 4, minh = 0.8, padding = 0.2, r = 0.1, hover = true, colour = game().C.BLUE,func = 'can_load_profile', button = "load_profile", shadow = true, focus_args = {nav = 'wide'}}, nodes={
              {n=game().UI.TEXT, config={text = _profile == game().SETTINGS.profile and localize('ui_current_profile') or profile_data and localize('ui_load_profile') or localize('ui_create_profile'), ref_value = 'load_button_text', scale = 0.5, colour = game().C.UI.TEXT_LIGHT}}
            }}
          }},
          {n=game().UI.ROW, config={align = "cm", padding = 0, minh = 0.7}, nodes={
            {n=game().UI.ROW, config={align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = game().C.RED,func = 'can_delete_profile', button = "delete_profile", shadow = true, focus_args = {nav = 'wide'}}, nodes={
              {n=game().UI.TEXT, config={text = _profile == game().SETTINGS.profile and localize('ui_reset_profile') or localize('ui_delete_profile'), scale = 0.3, colour = game().C.UI.TEXT_LIGHT}}
            }}
          }},
        }},
    }},
    }},
    {n=game().UI.ROW, config={align = "cm", padding = 0}, nodes={
      {n=game().UI.TEXT, config={id = 'warning_text', text = localize('hdr_click_confirm'), scale = 0.4, colour = game().C.CLEAR}}
    }}
  }} 
  return t
end


function M.build_profile_button()

  local letters = {}
  if game().F_DISP_USERNAME then
    for c in each_utf8_char(game().F_DISP_USERNAME) do
      local leng = game().LANGUAGES['all1'].font.FONT:hasGlyphs(c)
      letters[#letters+1] = {n=game().UI.TEXT, config={lang = game().LANGUAGES[leng and 'all1' or 'all2'],text = c, scale = 0.3, colour = Colour.blend_colours(game().C.GREEN, game().C.WHITE, 0.7), shadow = true}}
    end
  end

  if not game().PROFILES[game().SETTINGS.profile].name then 
    game().PROFILES[game().SETTINGS.profile].name = "P"..game().SETTINGS.profile
  end

 return {n=game().UI.ROOT, config = {align = "cm", colour = game().C.CLEAR}, nodes={
    {n=game().UI.ROW, config={align = "cm", padding = 0.2, r = 0.1, emboss = 0.1, colour = game().C.L_BLACK}, nodes={
      {n=game().UI.ROW, config={align = "cm"}, nodes={
        {n=game().UI.TEXT, config={text = localize('term_profile'), scale = 0.4, colour = game().C.UI.TEXT_LIGHT, shadow = true}}
      }},
      {n=game().UI.ROW, config={align = "cm"}, nodes={
        {n=game().UI.COLUMN, config={align = "cm", padding = 0.15, minw = 2, minh = 0.8, maxw = 2, r = 0.1, hover = true, colour = Colour.blend_colours(game().C.WHITE, game().C.GREY, 0.2), button = 'profile_select', shadow = true}, nodes={
          {n=game().UI.TEXT, config={ref_table = game().PROFILES[game().SETTINGS.profile], ref_value = 'name', scale = 0.4, colour = game().C.UI.TEXT_LIGHT, shadow = true}}
        }},
      }}
    }},
    game().F_DISP_USERNAME and {n=game().UI.ROW, config={align = "cm"}, nodes={
      {n=game().UI.ROW, config={align = "cm"}, nodes={
        {n=game().UI.TEXT, config={text = localize('term_playing_as'), scale = 0.3, colour = game().C.UI.TEXT_LIGHT, shadow = true}}
      }},
      {n=game().UI.ROW, config={align = "cm", minh = 0.12}, nodes={}},
      {n=game().UI.ROW, config={align = "cm", maxw = 2}, nodes=letters}
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
		return { n = game().UI.ROW, config = { align = "cm" }, nodes = {
			menu_button(id, label, action, colour),
		}}
	end

	local function gap_node()
		return {n=game().UI.COLUMN, config={minw = gap}, nodes={}}
	end

	local function mode_stack()
		return {n=game().UI.ROW, config=menu_mode_chrome(), nodes={
			mode_button('main_menu_classic', localize('ui_classic'), 'begin_classic_run', game().C.BLUE),
			{n=game().UI.ROW, config={minh = gap, minw = button_w}, nodes={}},
			mode_button('main_menu_time_run', localize('ui_time_run'), 'begin_time_run', game().C.GREEN),
		}}
	end

	return {
		n=game().UI.ROOT, config = {align = "cm", colour = game().C.CLEAR}, nodes={
			{n=game().UI.COLUMN, config={align = "cm", padding = 0}, nodes={
				{n=game().UI.ROW, config={
					id = "main_menu_mode_align_row",
					align = "cm",
					padding = 0,
					colour = game().C.CLEAR,
				}, nodes={
					mode_stack(),
				}},
				{n=game().UI.ROW, config={minh = stack_gap}, nodes={}},
				{n=game().UI.ROW, config=chrome, nodes={
					menu_button(nil, localize('ui_settings'), 'open_settings', game().C.ORANGE),
					gap_node(),
					menu_button(nil, localize('ui_quit_cap'), 'quit', game().C.RED),
				}},
			}},
		}}
end


function DEFINITIONS.language_selector()
  local rows = {}
  local langs = {}
  for k, v in pairs(game().LANGUAGES) do
    if not v.omit then 
      langs[#langs+1] = v
    end
  end
  table.sort(langs, (function(a, b) return a.label < b.label end))
  local _row = {}
  for k, v in ipairs(langs) do
    _row[#_row+1] = {n=game().UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minh = 0.7, minw = 4.5, button = 'change_lang', ref_table = v, colour = game().C.BLUE, hover = true, shadow = true, focus_args = {snap_to = (k == 1)}}, nodes={
      {n=game().UI.ROW, config={align = "cm"}, nodes={
        {n=game().UI.TEXT, config={text = v.label, lang = v, scale = 0.45, colour = game().C.UI.TEXT_LIGHT, shadow = true}}
      }}
    }}
    if _row[3] or (k == #langs) then 
      rows[#rows+1] = {n=game().UI.ROW, config={align = "cm", padding = 0.1}, nodes=_row}
      _row = {}
    end
  end
  
  local discord = Sprite(0,0,0.6,0.6,game().TEXTURE_ATLASES["icons"], {x=2, y=0})
  discord.states.drag.can = false

  local t = build_generic_options({contents ={
    {n=game().UI.ROW, config={align = "cm", padding = 0.05}, nodes=rows},
    {n=game().UI.ROW, config={align = "cm", padding = 0.05}, nodes={
      {n=game().UI.COLUMN, config={align = "cm", padding = 0.1, minw = 4, maxw = 4, r = 0.1, minh = 0.8, colour = Colour.blend_colours(game().C.GREEN, game().C.GREY, 0.4)}, nodes={
        {n=game().UI.OBJECT, config={object = discord}},
        {n=game().UI.TEXT, config={text = game().LANG.button, scale = 0.45, colour = game().C.UI.TEXT_LIGHT, shadow = true}}
      }},
    }}
  }})
  return t
end

return M
