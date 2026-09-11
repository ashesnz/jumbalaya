--[[ app/callbacks/window.lua - Window / graphics G.FUNCS registration ]]

local Bridge = require("app.controllers.callback_bridge")
local Settings = require("app.controllers.settings")

G.FUNCS.change_vsync = Bridge.wrap("change_vsync", Settings.change_vsync)
G.FUNCS.change_screen_resolution = Bridge.wrap("change_screen_resolution", Settings.change_screen_resolution)
G.FUNCS.change_screenmode = Bridge.wrap("change_screenmode", Settings.change_screenmode)
G.FUNCS.change_display = Bridge.wrap("change_display", Settings.change_display)
G.FUNCS.change_window_cycle_UI = Settings.change_window_cycle_UI
G.FUNCS.change_gamespeed = Bridge.wrap("change_gamespeed", Settings.change_gamespeed)
G.FUNCS.change_shadows = Bridge.wrap("change_shadows", Settings.change_shadows)
G.FUNCS.change_pixel_smoothing = Bridge.wrap("change_pixel_smoothing", Settings.change_pixel_smoothing)
G.FUNCS.can_apply_window_changes = Settings.can_apply_window_changes
G.FUNCS.apply_window_changes = Settings.apply_window_changes
