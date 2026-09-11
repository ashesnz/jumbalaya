--[[ app/effects/menu.lua - Main menu presentation effects ]]

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local ViewHost = require("jumbalaya-engine.panels.view_host")

local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end

local Menu = {}

function Menu.set_main_ui()
    g().MAIN_MENU_UI = ViewHost.create{
        definition = build_main_menu_buttons(),
        config = {
            align = "bmi",
            offset = {x = 0, y = main_menu_bottom_offset()},
            major = g().ROOM_ATTACH,
            bond = 'Weak',
        },
    }
    layout_main_menu()

    if g().F_PROFILE_BUTTON then
        Scheduler.add{
            blockable = false,
            blocking = false,
            func = function()
                if (not g().F_DISP_USERNAME) or type(g().F_DISP_USERNAME) == 'string' then
                    g().PROFILE_BUTTON = ViewHost.create{
                        definition = build_profile_button(),
                        config = {align = "bli", offset = {x = -10, y = 0}, major = g().ROOM_ATTACH, bond = 'Weak'},
                    }
                    g().PROFILE_BUTTON.alignment.offset.x = 0
                    g().PROFILE_BUTTON:align_to_major()
                    return true
                end
            end,
        }
    end

    if g().INPUT and g().MAIN_MENU_UI and g().MAIN_MENU_UI:find_node_by_id('main_menu_classic') then
        g().INPUT:snap_to{node = g().MAIN_MENU_UI:find_node_by_id('main_menu_classic')}
    end
end

return Menu