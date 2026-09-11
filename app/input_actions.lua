-- Application and development keyboard actions.

local game_access = require("word_game.model.game_access")

local BridgeRuntime = require("bridge.runtime")
local Funcs = require("bridge.funcs_registry")
local function g() return BridgeRuntime.game() end

local M = {}

function M.key_press(controller, key)
    if not _RELEASE_MODE then
        if key == 'tab' and not g().debug_tools then
            g().debug_panel = g().debug_panel or DEVTOOLS.DebugPanel(G)
            g().debug_panel:open()
        end
        if key == 'h' then
            g().debug_UI_toggle = not g().debug_UI_toggle
        elseif key == 'b' and g().STATE ~= g().STATES.TABLE_BOARD then
            g():discard_run()
            g():start_run({})
        elseif key == 'l' then
            g():discard_run()
            g().STORED_RUN = read_save_payload(g().SETTINGS.profile..'/'..'save.acs')
            if g().STORED_RUN ~= nil then g().STORED_RUN = unpack_source(g().STORED_RUN) end
            g():start_run({savetext = g().STORED_RUN})
        elseif key == 'j' then
            g().debug_splash_size_toggle = not g().debug_splash_size_toggle
            g():discard_run()
            g():open_main_menu('splash')
        elseif key == '8' then
            love.mouse.setVisible(not love.mouse.isVisible())
        elseif key == '9' then
            g().debug_tooltip_toggle = not g().debug_tooltip_toggle
        elseif key == 'v' then
            if not g().prof then
                g().prof = require 'devtools/profiler'
                g().prof.start()
            else
                g().prof:stop()
                print(g().prof.report())
                g().prof = nil
            end
        elseif key == 'p' then
            g().SETTINGS.perf_mode = not g().SETTINGS.perf_mode
        end
    end
end

function M.key_hold(controller, key, dt)
    if key == 'r' and not g().SETTINGS.paused and controller.held_key_times[key] > 0.7 then
        g():queue_settings_write()
        controller.held_key_times[key] = nil
        g().SETTINGS.current_setup = 'New Run'
        local game = game_access.get()
        game_access.patch({ viewed_back = nil })
        g().run_setup_seed = game and game.seeded
        g().forced_seed, g().setup_seed = nil, nil
        if game and game.seeded then g().forced_seed = game.seed_streams.seed end
        if g().STAGE == g().STAGES.RUN and g().FUNCS.begin_run then g().FUNCS.begin_run() end
        g().forced_seed = nil
    end
end

function M.key_release(controller, key)
    if key == 'a' and controller.held_keys['g'] and not _RELEASE_MODE then
        g().DEBUG = not g().DEBUG
    end
    if key == 'tab' and g().debug_tools then
        if g().debug_panel then
            g().debug_panel:close()
        else
            g().debug_tools:remove()
            g().debug_tools = nil
        end
    end
end

return M