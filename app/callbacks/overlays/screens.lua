--[[ app/callbacks/overlays/ ]]


G.FUNCS.open_options = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
    definition = build_options(),
  }
end
G.FUNCS.open_settings = function(e, instant)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
  definition = build_settings(),
  config = {offset = {x=0,y=instant and 0 or 10}}
}
end

G.FUNCS.language_selection = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
    definition = G.DEFINITIONS.language_selector(),
  }
end

G.FUNCS.change_viewed_back = function(args)
  G.GAME.viewed_back:change_to(G.P_CENTER_POOLS.Back[args.to_key])
  G.FUNCS.card_gallery_decks()
end

G.FUNCS.card_gallery = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
    definition = build_card_gallery(),
  }
end


G.FUNCS.card_gallery_decks = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
    definition = build_card_gallery_decks(),
  }
end

G.FUNCS.card_gallery_editions = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
    definition = build_card_gallery_editions(),
  }
end


G.FUNCS.show_high_scores = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
    definition = build_high_scores(),
  }
end

G.FUNCS.usage = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.show_overlay{
    definition = G.DEFINITIONS.usage_tabs()
  }
end

G.FUNCS.profile_select = function(e)
  G.SETTINGS.paused = true
  G.focused_profile = G.SETTINGS.profile

  for i = 1, 3 do
    if i ~= G.focused_profile and love.filesystem.getInfo(i..'/'..'profile.acs') then G:load_profile(i) end
  end
  G:load_profile(G.focused_profile)

  G.FUNCS.show_overlay{
    definition = G.DEFINITIONS.profile_select(),
  }
end

G.FUNCS.quit = function(e)
  love.event.quit()
end


G.FUNCS.warn_lang = function(e)
  local _infotip_object = G.OVERLAY_MENU:find_node_by_id('overlay_menu_infotip')
  if (_infotip_object.config.set ~= e.config.ref_table.label) and (not G.F_NO_ACHIEVEMENTS) then 
    _infotip_object.config.object:remove() 
    _infotip_object.config.object = LayoutView{
      definition = overlay_infotip({e.config.ref_table.warning[1],e.config.ref_table.warning[2],e.config.ref_table.warning[3], lang = e.config.ref_table}),
      config = {offset = {x=0,y=0}, align = 'bm', parent = _infotip_object}
    }
    _infotip_object.config.object.root_node:pulse()
    _infotip_object.config.set = e.config.ref_table.label
    e.config.disable_button = true
    Scheduler.add{mode = 'delayed', delay = 0.06, blockable = false, blocking = false, func = function()
      play_sfx('tarot2', 0.76, 0.4);return true end}

    Scheduler.add{mode = 'delayed', delay = 0.35, blockable = false, blocking = false, func = function()
      e.config.disable_button = nil;return true end}
      e.config.button = 'change_lang'
    play_sfx('tarot2', 1, 0.4)
  end
end



G.FUNCS.change_lang = function(e)
  local lang = e.config.ref_table
  if not lang or lang == G.LANG then 
    G.FUNCS.close_overlay()
  else
    G.SETTINGS.language = lang.key
    G:set_language()
    G.TIMELINE:flush()
    G.FUNCS.wipe_in()
    Scheduler.add{
      persistent = true,
      blockable = true, 
      blocking = false,
      func = function()
        G:discard_run()
        G:load_card_definitions()
        G:open_main_menu()
        return true
      end
    }
    G.FUNCS.wipe_out()
  end
end

G.FUNCS.copy_run_seed = function(e)
  if G.F_LOCAL_CLIPBOARD then
    G.CLIPBOARD = G.GAME.seed_streams.seed
  else
    love.system.setClipboardText(G.GAME.seed_streams.seed)
  end 
end
  G.FUNCS.show_infotip = function(e)
    if e.config.ref_table then 
      e.children.info = LayoutView{
        definition = {n=G.UI.ROOT, config = {align = 'cm', colour = G.C.CLEAR, padding = 0.02}, nodes=e.config.ref_table},
        config = {offset = {x=-0.03,y=0}, align = 'cl', parent = e}
      }
      e.children.info:align_to_major()
      e.config.ref_table = nil
    end
  end
