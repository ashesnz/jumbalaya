--[[ app/callbacks/overlays/menu_core.lua - Overlay menu FUNCS registration ]]

local dispatch_wrap = require("app.callbacks.controllers.dispatch_wrap")
local Overlays = require("app.callbacks.controllers.overlays")
local Funcs = require("app.callbacks.funcs")

Funcs.register("switch_tab", Overlays.switch_tab)
Funcs.register("show_overlay", dispatch_wrap.wrap("show_overlay", Overlays.show_overlay))
Funcs.register("close_overlay", dispatch_wrap.wrap("close_overlay", Overlays.close_overlay))
