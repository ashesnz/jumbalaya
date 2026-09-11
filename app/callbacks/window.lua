--[[ app/callbacks/window.lua - Window / graphics FUNCS registration ]]

local Bridge = require("app.controllers.callback_bridge")
local Settings = require("app.controllers.settings")
local Funcs = require("bridge.funcs_registry")

Funcs.register("change_vsync", Bridge.wrap("change_vsync", Settings.change_vsync))
Funcs.register("change_screen_resolution", Bridge.wrap("change_screen_resolution", Settings.change_screen_resolution))
Funcs.register("change_screenmode", Bridge.wrap("change_screenmode", Settings.change_screenmode))
Funcs.register("change_display", Bridge.wrap("change_display", Settings.change_display))
Funcs.register("change_window_cycle_UI", Settings.change_window_cycle_UI)
Funcs.register("change_gamespeed", Bridge.wrap("change_gamespeed", Settings.change_gamespeed))
Funcs.register("change_shadows", Bridge.wrap("change_shadows", Settings.change_shadows))
Funcs.register("change_pixel_smoothing", Bridge.wrap("change_pixel_smoothing", Settings.change_pixel_smoothing))
Funcs.register("can_apply_window_changes", Settings.can_apply_window_changes)
Funcs.register("apply_window_changes", Settings.apply_window_changes)
