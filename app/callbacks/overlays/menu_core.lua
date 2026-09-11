--[[ app/callbacks/overlays/menu_core.lua - Overlay menu G.FUNCS registration ]]

local Bridge = require("app.controllers.callback_bridge")
local Overlays = require("app.controllers.overlays")

G.FUNCS.switch_tab = Overlays.switch_tab
G.FUNCS.show_overlay = Bridge.wrap("show_overlay", Overlays.show_overlay)
G.FUNCS.close_overlay = Bridge.wrap("close_overlay", Overlays.close_overlay)
