-- Application and development keyboard actions.

local M = {}

function M.key_press(controller, key)
    if not _RELEASE_MODE then
        if key == 'tab' and not G.debug_tools then
            G.debug_panel = G.debug_panel or DEVTOOLS.DebugPanel(G)
            G.debug_panel:open()
        end
        if key == 'h' then
            G.debug_UI_toggle = not G.debug_UI_toggle
        elseif key == 'b' and G.STATE ~= G.STATES.TABLE_BOARD then
            G:discard_run()
            G:start_run({})
        elseif key == 'l' then
            G:discard_run()
            G.STORED_RUN = read_save_payload(G.SETTINGS.profile..'/'..'save.acs')
            if G.STORED_RUN ~= nil then G.STORED_RUN = unpack_source(G.STORED_RUN) end
            G:start_run({savetext = G.STORED_RUN})
        elseif key == 'j' then
            G.debug_splash_size_toggle = not G.debug_splash_size_toggle
            G:discard_run()
            G:open_main_menu('splash')
        elseif key == '8' then
            love.mouse.setVisible(not love.mouse.isVisible())
        elseif key == '9' then
            G.debug_tooltip_toggle = not G.debug_tooltip_toggle
        elseif key == 'v' then
            if not G.prof then
                G.prof = require 'devtools/profiler'
                G.prof.start()
            else
                G.prof:stop()
                print(G.prof.report())
                G.prof = nil
            end
        elseif key == 'p' then
            G.SETTINGS.perf_mode = not G.SETTINGS.perf_mode
        end
    end
end

function M.key_hold(controller, key, dt)
    if key == 'r' and not G.SETTINGS.paused and controller.held_key_times[key] > 0.7 then
        if not G.GAME.won then
            G.PROFILES[G.SETTINGS.profile].high_scores.current_streak.amt = 0
        end
        G:queue_settings_write()
        controller.held_key_times[key] = nil
        G.SETTINGS.current_setup = 'New Run'
        G.GAME.viewed_back = nil
        G.run_setup_seed = G.GAME.seeded
        G.forced_seed, G.setup_seed = nil, nil
        if G.GAME.seeded then G.forced_seed = G.GAME.seed_streams.seed end
        if G.STAGE == G.STAGES.RUN and G.FUNCS.begin_run then G.FUNCS.begin_run() end
        G.forced_seed = nil
    end
end

function M.key_release(controller, key)
    if key == 'a' and controller.held_keys['g'] and not _RELEASE_MODE then
        G.DEBUG = not G.DEBUG
    end
    if key == 'tab' and G.debug_tools then
        if G.debug_panel then
            G.debug_panel:close()
        else
            G.debug_tools:remove()
            G.debug_tools = nil
        end
    end
end

return M