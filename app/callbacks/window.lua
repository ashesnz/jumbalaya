G.FUNCS.change_vsync = function(args)
  G.SETTINGS.QUEUED_CHANGE.vsync = (G.SETTINGS.WINDOW.vsync == 0 and args.to_key == 1 and 1) or (G.SETTINGS.WINDOW.vsync == 1 and args.to_key == 2 and 0) or nil
end

--Changes the screen resolution to the cycled resolution.\
--Note - an issue with windows scaling above 100% means that these resolutions may not match the actual monitor resolution,
--they are more like render resolutions adjusted to fit the screen with scaling
--
---@param args {cycle_config: table, to_key: integer}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_key** The new resolution setting, refers to a resolution table generated with the option cycle
G.FUNCS.change_screen_resolution = function(args)
  local curr_disp = G.SETTINGS.WINDOW.selected_display
  local to_resolution = G.SETTINGS.WINDOW.DISPLAYS[curr_disp].screen_resolutions.values[args.to_key]
  G.SETTINGS.QUEUED_CHANGE.screenres = {w = to_resolution.w, h = to_resolution.h}

end

--Changes the screen mode\
--Options: Windowed, Fullscreen, Borderless
--
---@param args {cycle_config: table, to_key: integer}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_val** The new screenmode setting value
G.FUNCS.change_screenmode = function(args)
  G.ARGS.screenmode_vals = G.ARGS.screenmode_vals or {"Windowed", "Fullscreen", "Borderless"}
  G.SETTINGS.QUEUED_CHANGE.screenmode = G.ARGS.screenmode_vals[args.to_key]
  G.FUNCS.change_window_cycle_UI()
end

--Changes the displaying monitors
--
---@param args {cycle_config: table, to_key: integer}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_key** The new screenmode setting key
G.FUNCS.change_display = function(args)
  G.SETTINGS.QUEUED_CHANGE.selected_display = args.to_key
  G.FUNCS.change_window_cycle_UI()
end

--Helper function to re-add the resolution cycle UIE with updated data
G.FUNCS.change_window_cycle_UI = function()
  if G.OVERLAY_MENU then
    local swap_node = G.OVERLAY_MENU:find_node_by_id('resolution_cycle')
    if swap_node then
      local focused_display, focused_screenmode = G.SETTINGS.QUEUED_CHANGE.selected_display or G.SETTINGS.WINDOW.selected_display, G.SETTINGS.QUEUED_CHANGE.screenmode or G.SETTINGS.WINDOW.screenmode

      --Refresh the display information
      local res_option = enumerate_display_modes(focused_screenmode, focused_display)

      --Remove the old cycle, replace it with a new updated one reflecting any changes
      swap_node.children[1]:remove()
      swap_node.children[1] = nil
      swap_node.LayoutView:add_child(
        make_option_cycler({w = 4,scale = 0.8, options = G.SETTINGS.WINDOW.DISPLAYS[focused_display].screen_resolutions.strings, opt_callback = 'change_screen_resolution',current_option = res_option or 1}),
        swap_node)
    end
  end
end

--Changes the speed that the game runs at, does not affect all timers, just G.TIMERS.TOTAL
--
---@param args {cycle_config: table, to_val: number}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_val** The new screenmode setting key
G.FUNCS.change_gamespeed = function(args)
  G.SETTINGS.GAMESPEED = args.to_val
end

--Changes the relative position of play and discard buttons
--
---@param args {cycle_config: table, to_key: integer}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_val** The new screenmode setting key
--Changes the Shadow setting
--
---@param args {cycle_config: table, to_key: integer}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_val** The new value for shadows, 'On' or 'Off'
G.FUNCS.change_shadows = function(args)
  G.SETTINGS.GRAPHICS.shadows = args.to_key == 1 and 'On' or 'Off'
  G:queue_settings_write()
end

--Changes the Pixel smoothing, all sprites need to be realoaded when this changes\
--
---@param args {cycle_config: table, to_key: integer}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_val** The new value for shadows, 'On' or 'Off'
G.FUNCS.change_pixel_smoothing = function(args)
  G.SETTINGS.GRAPHICS.texture_scaling = args.to_key--^2
  G:set_render_settings()
  G:queue_settings_write()
end

--Changes the Bloom amount for the CRT effect, number of samples to take for bloom\
--
---@param args {cycle_config: table, to_key: number}
--**cycle_config** Is the config table from the original option cycle UIE\
--**to_val** The new value for shadows, 'On' or 'Off'
G.FUNCS.change_crt_bloom = function(args)
  G.SETTINGS.GRAPHICS.bloom = args.to_key
  G:queue_settings_write()
end
G.FUNCS.can_apply_window_changes = function(e)
  local can_apply = false
  if G.SETTINGS.QUEUED_CHANGE then 
    if G.SETTINGS.QUEUED_CHANGE.screenmode and
      G.SETTINGS.QUEUED_CHANGE.screenmode ~= G.SETTINGS.WINDOW.screenmode then
        can_apply = true
    elseif G.SETTINGS.QUEUED_CHANGE.screenres then
        can_apply = true
    elseif G.SETTINGS.QUEUED_CHANGE.vsync then
        can_apply = true
    elseif G.SETTINGS.QUEUED_CHANGE.selected_display and
           G.SETTINGS.QUEUED_CHANGE.selected_display ~= G.SETTINGS.WINDOW.selected_display then
        can_apply = true
    end
  end

  if can_apply then 
    e.config.button = 'apply_window_changes'
    e.config.colour = G.C.RED
  else
    e.config.button = nil
    e.config.colour = G.C.UI.BACKGROUND_INACTIVE
  end
end

--Applies all window changes, including updates to the screenmode, selected display, resolution and vsync.\
--These changes are all defined in the G.SETTINGS.QUEUED_CHANGE table. Any unchanged settings use the previous value
G.FUNCS.apply_window_changes = function(_initial)
  --Set the screenmode setting from Windowed, Fullscreen or Borderless
  G.SETTINGS.WINDOW.screenmode = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode) or G.SETTINGS.WINDOW.screenmode or 'Windowed'

  --Set the monitor the window should be rendered to
  G.SETTINGS.WINDOW.selected_display = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.selected_display) or G.SETTINGS.WINDOW.selected_display or 1

  enumerate_display_modes(G.SETTINGS.WINDOW.screenmode, G.SETTINGS.WINDOW.selected_display)
  local display_count = love.window.getDisplayCount()
  if G.SETTINGS.WINDOW.selected_display > display_count then
    G.SETTINGS.WINDOW.selected_display = display_count
  end
  if G.SETTINGS.WINDOW.selected_display < 1 then
    G.SETTINGS.WINDOW.selected_display = 1
  end

  --Set the screen resolution
  G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res = {
    w = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenres and G.SETTINGS.QUEUED_CHANGE.screenres.w) or (G.SETTINGS.screen_res and G.SETTINGS.screen_res.w) or love.graphics.getWidth( ),
    h = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenres and G.SETTINGS.QUEUED_CHANGE.screenres.h) or (G.SETTINGS.screen_res and G.SETTINGS.screen_res.h) or love.graphics.getHeight( )
  }

  --Set the vsync value, 0 is off 1 is on
  G.SETTINGS.WINDOW.vsync = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.vsync) or G.SETTINGS.WINDOW.vsync or 1

  love.window.updateMode(
    (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getWidth()*0.8 or G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res.w,
    (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getHeight()*0.8 or G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res.h,
    {fullscreen = G.SETTINGS.WINDOW.screenmode ~= 'Windowed',
    fullscreentype = (G.SETTINGS.WINDOW.screenmode == 'Borderless' and 'desktop') or (G.SETTINGS.WINDOW.screenmode == 'Fullscreen' and 'exclusive') or nil,
    vsync = G.SETTINGS.WINDOW.vsync,
    resizable = true,
    display = G.SETTINGS.WINDOW.selected_display
    })
  G.SETTINGS.QUEUED_CHANGE = {}
  if _initial ~= true then
    love.resize(love.graphics.getWidth(),love.graphics.getHeight())
    G:queue_settings_write()
  end
  if G.OVERLAY_MENU then
    local tab_but = G.OVERLAY_MENU:find_node_by_id('tab_but_Video')
    G.FUNCS.switch_tab(tab_but)
  end
end
