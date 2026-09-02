--[[ app/effects/menu.lua - Main menu presentation effects ]]

local Scheduler = require "app.effects.scheduler"

local Menu = {}

function Menu.set_main_ui()
    G.MAIN_MENU_UI = LayoutView{
        definition = build_main_menu_buttons(),
        config = {align = "bmi", offset = {x = 0, y = 10}, major = G.ROOM_ATTACH, bond = 'Weak'},
    }
    G.MAIN_MENU_UI.alignment.offset.y = 0
    G.MAIN_MENU_UI:align_to_major()

    G.MAIN_MENU_MODES_UI = LayoutView{
        definition = build_main_menu_mode_buttons(),
        config = {align = "cm", offset = {x = 0, y = 0}, major = G.ROOM_ATTACH, bond = 'Weak'},
    }
    layout_main_menu_mode_buttons()

    if G.F_PROFILE_BUTTON then
        Scheduler.add{
            blockable = false,
            blocking = false,
            func = function()
                if (not G.F_DISP_USERNAME) or type(G.F_DISP_USERNAME) == 'string' then
                    G.PROFILE_BUTTON = LayoutView{
                        definition = build_profile_button(),
                        config = {align = "bli", offset = {x = -10, y = 0}, major = G.ROOM_ATTACH, bond = 'Weak'},
                    }
                    G.PROFILE_BUTTON.alignment.offset.x = 0
                    G.PROFILE_BUTTON:align_to_major()
                    return true
                end
            end,
        }
    end

    if G.INPUT and G.MAIN_MENU_MODES_UI and G.MAIN_MENU_MODES_UI:find_node_by_id('main_menu_classic') then
        G.INPUT:snap_to{node = G.MAIN_MENU_MODES_UI:find_node_by_id('main_menu_classic')}
    end
end

return Menu