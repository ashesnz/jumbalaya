-- Application and development keyboard actions.

local BridgeRuntime = require("app.runtime")
local function game_access() return BridgeRuntime.game_access() end
local Funcs = require("app.callbacks.funcs")
local function game() return BridgeRuntime.game() end

local M = {}

function M.key_press(controller, key)
    if not _RELEASE_MODE then
        if key == 'tab' and not game().debug_tools then
            game().debug_panel = game().debug_panel or DEVTOOLS.DebugPanel(game())
            game().debug_panel:open()
        end
        if key == 'h' then
            game().debug_UI_toggle = not game().debug_UI_toggle
        elseif key == 'b' and game().STATE ~= game().STATES.TABLE_BOARD then
            game():discard_run()
            game():start_run({})
        elseif key == 'l' then
            game():discard_run()
            game().STORED_RUN = read_save_payload(game().SETTINGS.profile..'/'..'save.acs')
            if game().STORED_RUN ~= nil then game().STORED_RUN = unpack_source(game().STORED_RUN) end
            game():start_run({savetext = game().STORED_RUN})
        elseif key == 'j' then
            game().debug_splash_size_toggle = not game().debug_splash_size_toggle
            game():discard_run()
            game():open_main_menu('splash')
        elseif key == '8' then
            love.mouse.setVisible(not love.mouse.isVisible())
        elseif key == '9' then
            game().debug_tooltip_toggle = not game().debug_tooltip_toggle
        elseif key == 'v' then
            if not game().prof then
                game().prof = require 'devtools/profiler'
                game().prof.start()
            else
                game().prof:stop()
                print(game().prof.report())
                game().prof = nil
            end
        elseif key == 'p' then
            game().SETTINGS.perf_mode = not game().SETTINGS.perf_mode
        end
    end
end

function M.key_hold(controller, key, dt)
    if key == 'r' and not game().SETTINGS.paused and controller.held_key_times[key] > 0.7 then
        game():queue_settings_write()
        controller.held_key_times[key] = nil
        game().SETTINGS.current_setup = 'New Run'
        local access = game_access()
        local game = access and access.get()
        if access then access.patch({ viewed_back = nil }) end
        game().run_setup_seed = game and game.seeded
        game().forced_seed, game().setup_seed = nil, nil
        if game and game.seeded then game().forced_seed = game.seed_streams.seed end
        if game().STAGE == game().STAGES.RUN and Funcs.get("begin_run") then Funcs.dispatch("begin_run") end
        game().forced_seed = nil
    end
end

function M.key_release(controller, key)
    if key == 'a' and controller.held_keys['g'] and not _RELEASE_MODE then
        game().DEBUG = not game().DEBUG
    end
    if key == 'tab' and game().debug_tools then
        if game().debug_panel then
            game().debug_panel:close()
        else
            game().debug_tools:remove()
            game().debug_tools = nil
        end
    end
end

return M