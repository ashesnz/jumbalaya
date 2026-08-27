--[[ word_game/ui/overlays/options.lua - Pause menu and settings overlays ]]
local Scheduler = require "app.effects.scheduler"
local Components = require "word_game.ui.widgets.components"


function build_options()  
  local current_seed = nil
  local restart = nil
  local main_menu = nil
  local card_gallery = nil
  local credits = nil

  Scheduler.add{
    blockable = false,
    func = function()
      G.REFRESH_ALERTS = true
    return true
    end
  }

  if G.STAGE == G.STAGES.RUN then
    restart = Components.button{id = 'restart_button', label = {localize('ui_start_new_run')}, onClick = "begin_run", width = 5}
    main_menu = Components.button{ label = {localize('ui_main_menu')}, onClick = "return_to_menu", width = 5}
    card_gallery = Components.button{ label = {localize('ui_collection')}, onClick = "card_gallery", width = 5, id = 'card_gallery'}
    current_seed = {n=G.UI.ROW, config={align = "cm", padding = 0.05}, nodes={
        {n=G.UI.COLUMN, config={align = "cm", padding = 0}, nodes={
        {n=G.UI.TEXT, config={text = localize('ui_seed')..": ", scale = 0.4, colour = G.C.WHITE}}
      }},
      {n=G.UI.COLUMN, config={align = "cm", padding = 0, minh = 0.8}, nodes={
        {n=G.UI.COLUMN, config={align = "cm", padding = 0, minh = 0.8}, nodes={
          {n=G.UI.ROW, config={align = "cm", r = 0.1, colour = G.GAME.seeded and G.C.RED or G.C.BLACK, minw = 1.8, minh = 0.5, padding = 0.1, emboss = 0.05}, nodes={
            {n=G.UI.COLUMN, config={align = "cm"}, nodes={
              {n=G.UI.TEXT, config={ text = tostring(G.GAME.seed_streams.seed), scale = 0.43, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
            }}
          }}
        }}
      }},
      Components.button({col = true, onClick = 'copy_run_seed', label = {localize('ui_copy')}, colour = G.C.BLUE, textSize = 0.3, width = 1.3, height = 0.5,}),
    }}
  end
  if G.STAGE == G.STAGES.MAIN_MENU then
    credits = Components.button{ label = {localize('ui_credits')}, onClick = "show_credits", width = 5}
  end

  local settings = Components.button({onClick = 'open_settings', label = {localize('ui_settings')}, width = 5, focus_args = {snap_to = true}})
  local high_scores = Components.button{ label = {localize('ui_stats')}, onClick = "show_high_scores", width = 5}

  local t = build_generic_options({ contents = {
      settings,
      G.GAME.seeded and current_seed or nil,
      restart,
      main_menu,
      high_scores,
      card_gallery,
      credits
    }})
  return t
end


function build_settings()
  local tabs = {}
  tabs[#tabs+1] = {
    label = localize('ui_set_game'),
    chosen = true,
    tab_definition_function = G.DEFINITIONS.settings_tab,
    tab_definition_function_args = 'Game'
  }
  if G.F_VIDEO_SETTINGS then   tabs[#tabs+1] = {
      label = localize('ui_set_video'),
      tab_definition_function = G.DEFINITIONS.settings_tab,
      tab_definition_function_args = 'Video'
    }
  end
  tabs[#tabs+1] = {
    label = localize('ui_set_graphics'),
    tab_definition_function = G.DEFINITIONS.settings_tab,
    tab_definition_function_args = 'Graphics'
  }
  tabs[#tabs+1] = {
    label = localize('ui_set_audio'),
    tab_definition_function = G.DEFINITIONS.settings_tab,
    tab_definition_function_args = 'Audio'
  }

  local t = build_generic_options({back_func = 'open_options',contents = {make_tab_strip(
    {tabs = tabs,
    tab_h = 7.05,
    tab_alignment = 'tm',
    snap_to_nav = true}
    )}})
return t
end


function G.DEFINITIONS.settings_tab(tab)
  if tab == 'Game' then
    return {n=G.UI.ROOT, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
      Components.cycler({label = localize('ui_set_gamespeed'),scale = 0.8, options = {0.5, 1, 2, 4}, onChange = 'change_gamespeed', current_option = (G.SETTINGS.GAMESPEED == 0.5 and 1 or G.SETTINGS.GAMESPEED == 4 and 4 or G.SETTINGS.GAMESPEED + 1)}),
      Components.cycler({width = 5, label = localize('ui_set_play_discard_pos'),scale = 0.8, options = localize('opt_play_discard_pos_opt'), onChange = 'change_play_discard_position', current_option = (G.SETTINGS.play_button_pos)}),
      G.F_RUMBLE and Components.toggle({label = localize('ui_set_rumble'), ref_table = G.SETTINGS, ref_value = 'rumble'}) or nil,
      Components.slider({label = localize('ui_set_screenshake'),width = 4, height = 0.4, ref_table = G.SETTINGS, ref_value = 'screenshake', min = 0, max = 100}),
      Components.toggle({label = localize('ui_high_contrast_cards'), ref_table = G.SETTINGS, ref_value = 'colourblind_option'}),
      G.F_CRASH_REPORTS and Components.toggle({label = localize('ui_set_crash_reports'), ref_table = G.SETTINGS, ref_value = 'crashreports', info = localize('opt_crash_report_info')}) or nil,
    }}
  elseif tab == 'Video' then
    --Reset the queue so there are no pending changes
    G.SETTINGS.QUEUED_CHANGE = {}
  
    --Refresh the display information for all displays based on the screenmode selected
    local res_option = enumerate_display_modes(G.SETTINGS.WINDOW.screenmode, G.SETTINGS.WINDOW.selected_display)
  
    return
    {n=G.UI.ROOT, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
        Components.cycler({width = 4,scale = 0.8, label = localize('ui_set_monitor'), options = G.SETTINGS.WINDOW.display_names, onChange = 'change_display', current_option = (G.SETTINGS.WINDOW.selected_display)}),
        Components.cycler({width = 4,scale = 0.8, label = localize('ui_set_windowmode'), options = localize('opt_windowmode_opt'), onChange = 'change_screenmode', current_option = (({Windowed = 1, Fullscreen = 2, Borderless = 3})[G.SETTINGS.WINDOW.screenmode] or 1)}),
        {n=G.UI.ROW, config={align = "cm", id = 'resolution_cycle'}, nodes={Components.cycler({width = 4,scale = 0.8, options = G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_resolutions.strings, onChange = 'change_screen_resolution',current_option = res_option or 1})}},
        {n=G.UI.ROW, config={align = "cm"}, nodes={Components.cycler({width = 4,scale = 0.8, options = localize('opt_vsync_opt'), onChange = 'change_vsync',current_option = G.SETTINGS.WINDOW.vsync == 0 and 2 or 1})}},
        Components.button({onClick = 'apply_window_changes', label = {localize('ui_set_apply')}, width = 3, onTick = 'can_apply_window_changes'}),
    }}
  elseif tab == 'Audio' then
    return {n=G.UI.ROOT, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
      Components.slider({label = localize('ui_set_master_vol'), width = 5, height = 0.4, ref_table = G.SETTINGS.SOUND, ref_value = 'volume', min = 0, max = 100}),
      Components.slider({label = localize('ui_set_music_vol'), width = 5, height = 0.4, ref_table = G.SETTINGS.SOUND, ref_value = 'music_volume', min = 0, max = 100}),
      Components.slider({label = localize('ui_set_game_vol'), width = 5, height = 0.4, ref_table = G.SETTINGS.SOUND, ref_value = 'game_sounds_volume', min = 0, max = 100}),
    }}
  elseif tab == 'Graphics' then
    return {n=G.UI.ROOT, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
      Components.cycler({width = 4,scale = 0.8, label = localize("ui_set_shadows"),options = localize('opt_shadow_opt'), onChange = 'change_shadows', current_option = (G.SETTINGS.GRAPHICS.shadows == 'On' and 1 or 2)}),
      Components.cycler({width = 4,scale = 0.8, label = localize("ui_set_pixel_smoothing"),options = localize('opt_smoothing_opt'), onChange = 'change_pixel_smoothing', current_option = G.SETTINGS.GRAPHICS.texture_scaling}),
    }}
  end

  return {n=G.UI.ROOT, config={align = "cm", padding = 0.05, colour = G.C.CLEAR, minh = 5, minw = 5}, nodes={}}
end
