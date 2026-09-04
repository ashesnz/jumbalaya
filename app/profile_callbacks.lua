-- Application profile and save callbacks.

--Determines if there is a valid save file to load and continue from main menu
--
---@param e {}
--**e** Is the UIE that called this function

local Scheduler = require "app.effects.timeline_scheduler"
G.FUNCS.can_resume_run = function(e)
  if e.config.func then --refers to this function, or 'can_resume_run', so this doesn't run repeatedly
    local _can_continue = nil
    local savefile = love.filesystem.getInfo(G.SETTINGS.profile..'/'..'save.acs')
    if savefile == nil then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
      if not G.STORED_RUN then
        G.STORED_RUN = read_save_payload(G.SETTINGS.profile..'/'..'save.acs')
        if G.STORED_RUN ~= nil then G.STORED_RUN = unpack_source(G.STORED_RUN) end
      end
      if not G.STORED_RUN.VERSION or G.STORED_RUN.VERSION < '0.9.2' then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
      else
        _can_continue = true
      end
    end
    e.config.func = nil
    return _can_continue
  end
end

G.FUNCS.can_load_profile = function(e)
  if G.SETTINGS.profile == G.focused_profile then
      e.config.colour = G.C.UI.BACKGROUND_INACTIVE
      e.config.button = nil
  else
    e.config.colour = G.C.BLUE
    e.config.button = 'load_profile'
  end
end

G.FUNCS.load_profile = function(delete_prof_data)
  G.STORED_RUN = nil
  G:queue_wipe_transition({
    function()
      G:discard_run()
      local _name = nil
      if G.PROFILES[G.focused_profile].name and G.PROFILES[G.focused_profile].name ~= '' then
        _name = G.PROFILES[G.focused_profile].name
      end
      if delete_prof_data then G.PROFILES[G.focused_profile] = {} end
      G.DISCOVER_TALLIES = nil
      G.PROGRESS = nil
      G:load_profile(G.focused_profile)
      G.PROFILES[G.focused_profile].name = _name
      G:load_card_definitions()
      return true
    end,
    {
      blockable = true,
      blocking = false,
      func = function()
        G:open_main_menu()
        G.WRITE_FLAGS.force = true
        return true
      end,
    },
  }, { flush_timeline = true })
end

G.FUNCS.can_delete_profile = function(e)
  G.CHECK_PROFILE_DATA = G.CHECK_PROFILE_DATA or love.filesystem.getInfo(G.focused_profile..'/'..'profile.acs')
  if (not G.CHECK_PROFILE_DATA) or e.config.disable_button then
      G.CHECK_PROFILE_DATA = false
      e.config.colour = G.C.UI.BACKGROUND_INACTIVE
      e.config.button = nil
  else
    e.config.colour = G.C.RED
    e.config.button = 'delete_profile'
  end
end

G.FUNCS.delete_profile = function(e)
  local warning_text = e.LayoutView:find_node_by_id('warning_text')
  if warning_text.config.colour ~= G.C.WHITE then 
    warning_text:pulse()
    warning_text.config.colour = G.C.WHITE
    warning_text.config.shadow = true
    e.config.disable_button = true
    Scheduler.add{mode = 'delayed', delay = 0.06, blockable = false, blocking = false, func = function()
      play_sfx('tarot2', 0.76, 0.4);return true end}

    Scheduler.add{mode = 'delayed', delay = 0.35, blockable = false, blocking = false, func = function()
      e.config.disable_button = nil;return true end}

    play_sfx('tarot2', 1, 0.4)
  else
    love.filesystem.remove(G.focused_profile..'/'..'profile.acs')
    love.filesystem.remove(G.focused_profile..'/'..'save.acs')
    love.filesystem.remove(G.focused_profile..'/'..'meta.acs')
    love.filesystem.remove(G.focused_profile..'')
    G.STORED_RUN = nil
    G.DISCOVER_TALLIES = nil
    G.PROGRESS = nil
    G.PROFILES[G.focused_profile] = {}
    if G.focused_profile == G.SETTINGS.profile then
        G.FUNCS.load_profile(true)
    else
      local tab_but = G.OVERLAY_MENU:find_node_by_id('tab_but_'..G.focused_profile)
      G.FUNCS.switch_tab(tab_but)
    end
  end
end