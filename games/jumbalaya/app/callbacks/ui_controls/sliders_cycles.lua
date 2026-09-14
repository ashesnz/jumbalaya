--[[ app/callbacks/ui_controls/sliders_cycles.lua - Slider / cycle game().FUNCS registration ]]

local game = require("app.runtime").game

local UIControls = require("app.callbacks.controllers.ui_controls")
local Funcs = require("app.callbacks.funcs")


Funcs.register("drag_slider", UIControls.drag_slider)
Funcs.register("slider_step", UIControls.slider_step)
Funcs.register("cycle_option", UIControls.cycle_option)
