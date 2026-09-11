--[[ app/callbacks/window.lua - Window / graphics FUNCS registration ]]

local dispatch_wrap = require("app.callbacks.controllers.dispatch_wrap")
local Settings = require("app.callbacks.controllers.settings")
local Funcs = require("app.callbacks.funcs")

Funcs.register("change_vsync", dispatch_wrap.wrap("change_vsync", Settings.change_vsync))
Funcs.register("change_screen_resolution", dispatch_wrap.wrap("change_screen_resolution", Settings.change_screen_resolution))
Funcs.register("change_screenmode", dispatch_wrap.wrap("change_screenmode", Settings.change_screenmode))
Funcs.register("change_display", dispatch_wrap.wrap("change_display", Settings.change_display))
Funcs.register("change_window_cycle_UI", Settings.change_window_cycle_UI)
Funcs.register("change_gamespeed", dispatch_wrap.wrap("change_gamespeed", Settings.change_gamespeed))
Funcs.register("change_shadows", dispatch_wrap.wrap("change_shadows", Settings.change_shadows))
Funcs.register("change_pixel_smoothing", dispatch_wrap.wrap("change_pixel_smoothing", Settings.change_pixel_smoothing))
Funcs.register("can_apply_window_changes", Settings.can_apply_window_changes)
Funcs.register("apply_window_changes", Settings.apply_window_changes)
