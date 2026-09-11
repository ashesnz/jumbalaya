-- Application profile and save callbacks.

--Determines if there is a valid save file to load and continue from main menu
--**e** Is the UIE that called this function

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"

local BridgeRuntime = require("app.runtime")
local Funcs = require("app.callbacks.funcs")
local function g() return BridgeRuntime.game() end
---@param e table
Funcs.register("can_resume_run",  function(e)
  if e.config.func then --refers to this function, or 'can_resume_run', so this doesn't run repeatedly
    local _can_continue = nil
    local savefile = love.filesystem.getInfo(g().SETTINGS.profile..'/'..'save.acs')
    if savefile == nil then
        e.config.colour = g().C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
      if not g().STORED_RUN then
        g().STORED_RUN = read_save_payload(g().SETTINGS.profile..'/'..'save.acs')
        if g().STORED_RUN ~= nil then g().STORED_RUN = unpack_source(g().STORED_RUN) end
      end
      local domain = rawget(_G, "WORD_GAME")
      local schema_ok = domain
        and domain.Persistence
        and domain.Persistence.SaveSchema
        and domain.Persistence.SaveSchema.is_loadable(g().STORED_RUN)
      if not g().STORED_RUN.VERSION or g().STORED_RUN.VERSION < '0.9.2' or not schema_ok then
        e.config.colour = g().C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
      else
        _can_continue = true
      end
    end
    e.config.func = nil
    return _can_continue
  end
end)

Funcs.register("can_load_profile",  function(e)
  if g().SETTINGS.profile == g().focused_profile then
      e.config.colour = g().C.UI.BACKGROUND_INACTIVE
      e.config.button = nil
  else
    e.config.colour = g().C.BLUE
    e.config.button = 'load_profile'
  end
end)

Funcs.register("load_profile",  function(delete_prof_data)
  g().STORED_RUN = nil
  g():queue_wipe_transition({
    function()
      g():discard_run()
      local _name = nil
      if g().PROFILES[g().focused_profile].name and g().PROFILES[g().focused_profile].name ~= '' then
        _name = g().PROFILES[g().focused_profile].name
      end
      if delete_prof_data then g().PROFILES[g().focused_profile] = {} end
      g().DISCOVER_TALLIES = nil
      g().PROGRESS = nil
      g():load_profile(g().focused_profile)
      g().PROFILES[g().focused_profile].name = _name
      g():load_card_definitions()
      return true
    end,
    {
      blockable = true,
      blocking = false,
      func = function()
        g():open_main_menu()
        g().WRITE_FLAGS.force = true
        return true
      end,
    },
  }, { flush_timeline = true })
end)

Funcs.register("can_delete_profile",  function(e)
  g().CHECK_PROFILE_DATA = g().CHECK_PROFILE_DATA or love.filesystem.getInfo(g().focused_profile..'/'..'profile.acs')
  if (not g().CHECK_PROFILE_DATA) or e.config.disable_button then
      g().CHECK_PROFILE_DATA = false
      e.config.colour = g().C.UI.BACKGROUND_INACTIVE
      e.config.button = nil
  else
    e.config.colour = g().C.RED
    e.config.button = 'delete_profile'
  end
end)

Funcs.register("delete_profile",  function(e)
  local warning_text = e.panel:find_node_by_id('warning_text')
  if warning_text.config.colour ~= g().C.WHITE then 
    warning_text:pulse()
    warning_text.config.colour = g().C.WHITE
    warning_text.config.shadow = true
    e.config.disable_button = true
    Scheduler.add{mode = 'delayed', delay = 0.06, blockable = false, blocking = false, func = function()
      play_sfx('generic1', 0.76, 0.4);return true end}

    Scheduler.add{mode = 'delayed', delay = 0.35, blockable = false, blocking = false, func = function()
      e.config.disable_button = nil;return true end}

    play_sfx('generic1', 1, 0.4)
  else
    love.filesystem.remove(g().focused_profile..'/'..'profile.acs')
    love.filesystem.remove(g().focused_profile..'/'..'save.acs')
    love.filesystem.remove(g().focused_profile..'/'..'meta.acs')
    love.filesystem.remove(g().focused_profile..'')
    g().STORED_RUN = nil
    g().DISCOVER_TALLIES = nil
    g().PROGRESS = nil
    g().PROFILES[g().focused_profile] = {}
    if g().focused_profile == g().SETTINGS.profile then
        Funcs.dispatch("load_profile", true)
    else
      local tab_but = g().OVERLAY_MENU:find_node_by_id('tab_but_'..g().focused_profile)
      Funcs.dispatch("switch_tab", tab_but)
    end
  end
end)