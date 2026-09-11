--[[ app/callbacks/overlays/menu_core.lua - Overlay menu FUNCS registration ]]

local Bridge = require("app.controllers.callback_bridge")
local Overlays = require("app.controllers.overlays")
local Funcs = require("app.callbacks.funcs")

Funcs.register("switch_tab", Overlays.switch_tab)
Funcs.register("show_overlay", Bridge.wrap("show_overlay", Overlays.show_overlay))
Funcs.register("close_overlay", Bridge.wrap("close_overlay", Overlays.close_overlay))
