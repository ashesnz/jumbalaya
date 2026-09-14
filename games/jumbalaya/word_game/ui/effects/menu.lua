--[[
	word_game/ui/effects/menu.lua — Main-menu title motion and panel entrance FX.
	Inputs: MAIN_MENU_UI nodes, TIMELINE, ViewHost.
	Outputs: menu effect helpers called from menu/animate and boot.
]]

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local ViewHost = require("jumbalaya-engine.panels.view_host")

local game = require("word_game.ui.util.game_runtime").game

local Menu = {}

function Menu.set_main_ui()
    game().MAIN_MENU_UI = ViewHost.create{
        definition = build_main_menu_buttons(),
        config = {
            align = "bmi",
            offset = {x = 0, y = main_menu_bottom_offset()},
            major = game().ROOM_ATTACH,
            bond = 'Weak',
        },
    }
    layout_main_menu()

    if game().F_PROFILE_BUTTON then
        Scheduler.add{
            blockable = false,
            blocking = false,
            func = function()
                if (not game().F_DISP_USERNAME) or type(game().F_DISP_USERNAME) == 'string' then
                    game().PROFILE_BUTTON = ViewHost.create{
                        definition = build_profile_button(),
                        config = {align = "bli", offset = {x = -10, y = 0}, major = game().ROOM_ATTACH, bond = 'Weak'},
                    }
                    game().PROFILE_BUTTON.alignment.offset.x = 0
                    game().PROFILE_BUTTON:align_to_major()
                    return true
                end
            end,
        }
    end

    if game().INPUT and game().MAIN_MENU_UI and game().MAIN_MENU_UI:find_node_by_id('main_menu_classic') then
        game().INPUT:snap_to{node = game().MAIN_MENU_UI:find_node_by_id('main_menu_classic')}
    end
end

return Menu