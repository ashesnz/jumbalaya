-- Application profile and save callbacks.

--Determines if there is a valid save file to load and continue from main menu
--**e** Is the UIE that called this function

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"

local BridgeRuntime = require("app.runtime")
local Funcs = require("app.callbacks.funcs")
local function game() return BridgeRuntime.game() end
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
---@param e table
Funcs.register("can_resume_run",  function(e)
  if e.config.func then --refers to this function, or 'can_resume_run', so this doesn't run repeatedly
    local _can_continue = nil
    local savefile = love.filesystem.getInfo(game().SETTINGS.profile..'/'..'save.acs')
    if savefile == nil then
        e.config.colour = game().C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
      if not game().STORED_RUN then
        game().STORED_RUN = read_save_payload(game().SETTINGS.profile..'/'..'save.acs')
        if game().STORED_RUN ~= nil then game().STORED_RUN = unpack_source(game().STORED_RUN) end
      end
      local domain = rawget(_G, "WORD_GAME")
      local schema_ok = domain
        and domain.Persistence
        and domain.Persistence.SaveSchema
        and domain.Persistence.SaveSchema.is_loadable(game().STORED_RUN)
      if not game().STORED_RUN.VERSION or game().STORED_RUN.VERSION < '0.9.2' or not schema_ok then
        e.config.colour = game().C.UI.BACKGROUND_INACTIVE
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
  if game().SETTINGS.profile == game().focused_profile then
      e.config.colour = game().C.UI.BACKGROUND_INACTIVE
      e.config.button = nil
  else
    e.config.colour = game().C.BLUE
    e.config.button = 'load_profile'
  end
end)

Funcs.register("load_profile",  function(delete_prof_data)
  game().STORED_RUN = nil
  game():queue_wipe_transition({
    function()
      game():discard_run()
      local _name = nil
      if game().PROFILES[game().focused_profile].name and game().PROFILES[game().focused_profile].name ~= '' then
        _name = game().PROFILES[game().focused_profile].name
      end
      if delete_prof_data then game().PROFILES[game().focused_profile] = {} end
      game().DISCOVER_TALLIES = nil
      game().PROGRESS = nil
      game():load_profile(game().focused_profile)
      game().PROFILES[game().focused_profile].name = _name
      game():load_card_definitions()
      return true
    end,
    {
      blockable = true,
      blocking = false,
      func = function()
        game():open_main_menu()
        game().WRITE_FLAGS.force = true
        return true
      end,
    },
  }, { flush_timeline = true })
end)

Funcs.register("can_delete_profile",  function(e)
  game().CHECK_PROFILE_DATA = game().CHECK_PROFILE_DATA or love.filesystem.getInfo(game().focused_profile..'/'..'profile.acs')
  if (not game().CHECK_PROFILE_DATA) or e.config.disable_button then
      game().CHECK_PROFILE_DATA = false
      e.config.colour = game().C.UI.BACKGROUND_INACTIVE
      e.config.button = nil
  else
    e.config.colour = game().C.RED
    e.config.button = 'delete_profile'
  end
end)

Funcs.register("delete_profile",  function(e)
  local warning_text = e.panel:find_node_by_id('warning_text')
  if warning_text.config.colour ~= game().C.WHITE then 
    warning_text:pulse()
    warning_text.config.colour = game().C.WHITE
    warning_text.config.shadow = true
    e.config.disable_button = true
    Scheduler.add{mode = 'delayed', delay = 0.06, blockable = false, blocking = false, func = function()
      play_sfx('generic1', 0.76, 0.4);return true end}

    Scheduler.add{mode = 'delayed', delay = 0.35, blockable = false, blocking = false, func = function()
      e.config.disable_button = nil;return true end}

    play_sfx('generic1', 1, 0.4)
  else
    love.filesystem.remove(game().focused_profile..'/'..'profile.acs')
    love.filesystem.remove(game().focused_profile..'/'..'save.acs')
    love.filesystem.remove(game().focused_profile..'/'..'meta.acs')
    love.filesystem.remove(game().focused_profile..'')
    game().STORED_RUN = nil
    game().DISCOVER_TALLIES = nil
    game().PROGRESS = nil
    game().PROFILES[game().focused_profile] = {}
    if game().focused_profile == game().SETTINGS.profile then
        Funcs.dispatch("load_profile", true)
    else
      local tab_but = game().OVERLAY_MENU:find_node_by_id('tab_but_'..game().focused_profile)
      Funcs.dispatch("switch_tab", tab_but)
    end
  end
end)