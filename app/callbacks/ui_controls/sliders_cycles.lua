--[[ app/callbacks/ui_controls/sliders_cycles.lua - Slider / cycle g().FUNCS registration ]]

local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end

local UIControls = require("app.controllers.ui_controls")
local Funcs = require("app.callbacks.funcs")


Funcs.register("drag_slider", UIControls.drag_slider)
Funcs.register("slider_step", UIControls.slider_step)
Funcs.register("cycle_option", UIControls.cycle_option)
