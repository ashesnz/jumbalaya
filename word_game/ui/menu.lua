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


local MODE_BUTTON_GAP_PX = 20

local function menu_button_chrome()
	return {
		align = "cm",
		padding = 0.24,
		r = Components.CHROME.radius,
		colour = G.C.L_BLACK,
		mid = true,
	}
end

function layout_main_menu_mode_buttons()
	if not G.MAIN_MENU_MODES_UI or not G.MAIN_MENU_MODES_UI.T then return end
	if not G.MAIN_MENU_UI or not G.MAIN_MENU_UI.T then return end

	G.MAIN_MENU_UI:recalculate()
	G.MAIN_MENU_UI:align_to_major()
	G.MAIN_MENU_MODES_UI:recalculate()

	local w = G.MAIN_MENU_MODES_UI.T.w or 0
	local h = G.MAIN_MENU_MODES_UI.T.h or 0
	local ts = (G.TILESIZE or 1) * (G.TILESCALE or 1)
	local gap = MODE_BUTTON_GAP_PX / ts
	local bar = G.MAIN_MENU_UI
	local x = bar.T.x + bar.T.w * 0.5 - w * 0.5
	local y = bar.T.y - gap - h

	G.MAIN_MENU_MODES_UI.T.x = x
	G.MAIN_MENU_MODES_UI.T.y = y
	if G.MAIN_MENU_MODES_UI.hard_set_T then
		G.MAIN_MENU_MODES_UI:hard_set_T(x, y, w, h)
	end
end

function build_main_menu_mode_buttons()
	local text_size = 0.58
	local button_w, button_h = 3.4, 1.15
	local gap = 0.22

	local function mode_button(id, label, action, colour)
		return { n = G.UI.ROW, config = {
			align = "cm",
			minw = button_w,
			maxw = button_w,
			minh = button_h,
			maxh = button_h,
			padding = 0,
		}, nodes = {
			Components.button{
				id = id,
				onClick = action,
				colour = colour,
				width = button_w,
				minw = button_w,
				maxw = button_w,
				height = button_h,
				minh = button_h,
				label = {label},
				textSize = text_size,
			},
		}}
	end

	return {
		n=G.UI.ROOT, config = {align = "cm", colour = G.C.CLEAR, minw = button_w}, nodes={
			{n=G.UI.COLUMN, config=menu_button_chrome(), nodes={
				mode_button('main_menu_classic', localize('ui_classic'), 'begin_classic_run', G.C.BLUE),
				{n=G.UI.ROW, config={minh = gap, minw = button_w}, nodes={}},
				mode_button('main_menu_time_run', localize('ui_time_run'), 'begin_time_run', G.C.GREEN),
			}},
		}}
end

function build_main_menu_buttons()
	local text_size = 0.58
	local button_w, button_h = 3.4, 1.15
	local gap = 0.22
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

	local function gap_node()
		return {n=G.UI.COLUMN, config={minw = gap}, nodes={}}
	end

	local t = {
		n=G.UI.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes={
			{n=G.UI.ROW, config=chrome, nodes={
				menu_button(nil, localize('ui_settings'), 'open_settings', G.C.ORANGE),
				gap_node(),
				menu_button(nil, localize('ui_stats'), 'show_high_scores', G.C.FILTER),
				gap_node(),
				menu_button(nil, localize('ui_quit_cap'), 'quit', G.C.RED),
			}},
		}}
	return t
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


