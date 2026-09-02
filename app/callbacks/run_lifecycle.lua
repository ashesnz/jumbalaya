
G.FUNCS.setup_run = function(e)
  G.FUNCS.begin_run(e)
end

G.FUNCS.notify_then_start_run = function(e)
  G.OVERLAY_MENU:remove()
  G.OVERLAY_MENU = nil
  G.FUNCS.begin_run(e)
end

G.FUNCS.notify_then_setup_run = G.FUNCS.notify_then_start_run

G.FUNCS.begin_run = function(e, args)
  G.SETTINGS.paused = false
  if e and e.config.id == 'restart_button' then G.GAME.viewed_back = nil end
  G.TIMELINE:flush()
  G:queue_during_wipe(function()
    G:discard_run()
    G:start_run(args)
    G:start_gameplay_board()
  end)
end

G.FUNCS.begin_classic_run = function(e)
  G.FUNCS.begin_run(e, { run_mode = "classic" })
end

G.FUNCS.begin_time_run = function(e)
  G.FUNCS.begin_run(e, { run_mode = "time_run" })
end

G.FUNCS.return_to_menu = function(e)
  G:queue_wipe_transition({
    function()
      G:discard_run()
      return true
    end,
    {
      blockable = true,
      blocking = false,
      func = function()
        G:open_main_menu('game')
        return true
      end,
    },
  }, { flush_timeline = true, pause = true })
end
