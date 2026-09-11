--[[
	jumbalaya-engine/services/input.lua - Typed action map (func name → store dispatch).

	Low-level pointer/gamepad routing lives in jumbalaya-engine/interaction/.
]]

local shell = require("jumbalaya-engine.shell")
local function g() return shell.game() end

---@class InputService
local InputService = {}
InputService.__index = InputService

InputService.ACTION_MAP = {
	play_placement_word = { type = "PLAY_WORD" },
	shuffle_hand = { type = "SHUFFLE_HAND" },
	jumble_next = { type = "JUMBLE_NEXT" },
	return_placement_cards = { type = "RETURN_PLACEMENT_CARDS" },
	end_run_from_sidebar = { type = "RUN_MATCH_END", won = false },
	classic_stage_next = { type = "CLASSIC_STAGE_NEXT" },
	trade_pick = { type = "TRADE_PICK" },
	trade_skip = { type = "TRADE_SKIP" },
	trade_skip_add = { type = "TRADE_SKIP_ADD" },
	trade_skip_remove = { type = "TRADE_SKIP_REMOVE" },
	begin_run = { type = "APP_BEGIN_RUN" },
	begin_classic_run = { type = "APP_BEGIN_RUN", run_mode = "classic" },
	begin_time_run = { type = "APP_BEGIN_RUN", run_mode = "time_run" },
	return_to_menu = { type = "APP_RETURN_TO_MENU" },
	show_overlay = { type = "APP_SHOW_OVERLAY" },
	close_overlay = { type = "APP_CLOSE_OVERLAY" },
	change_vsync = { type = "APP_SETTINGS_CHANGE", setting = "vsync" },
	change_screen_resolution = { type = "APP_SETTINGS_CHANGE", setting = "screenres" },
	change_screenmode = { type = "APP_SETTINGS_CHANGE", setting = "screenmode" },
	change_display = { type = "APP_SETTINGS_CHANGE", setting = "selected_display" },
	change_gamespeed = { type = "APP_SETTINGS_CHANGE", setting = "gamespeed" },
	change_shadows = { type = "APP_SETTINGS_CHANGE", setting = "shadows" },
	change_pixel_smoothing = { type = "APP_SETTINGS_CHANGE", setting = "pixel_smoothing" },
	drag_slider = { type = "APP_SETTINGS_CHANGE", setting = "slider" },
}

function InputService.new(store)
	return setmetatable({ _store = store }, InputService)
end

function InputService:on_pointer_down(x, y)
	local result = { hit = false, x = x, y = y }
	if g() and g().INPUT and g().INPUT.hover_state and g().INPUT.hover_state.target then
		result.hit = true
		result.target = g().INPUT.hover_state.target
	end
	return result
end

function InputService:action_for_func(name)
	return self.ACTION_MAP[name]
end

function InputService:on_action(action)
	if not action then return end
	if action.type and action.type:match("^APP_") then
		shell.emit_app_action(action)
		return
	end
	if self._store then
		self._store:dispatch(action)
	end
end

function InputService:dispatch_func(name, extra)
	local template = self.ACTION_MAP[name]
	if not template then return false end
	local action = {}
	for key, value in pairs(template) do
		action[key] = value
	end
	if extra then
		for key, value in pairs(extra) do
			action[key] = value
		end
	end
	self:on_action(action)
	return true
end

return InputService
