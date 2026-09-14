--[[ word_game/ui/tutorial/first_play/session.lua - Active tutorial visit state ]]

local GameRT = require("word_game.ui.util.game_runtime")

local M = {}

local active = false
local step_index = 1
local overlay_colour = { 0.06, 0.08, 0.12, 0 }
local bubble_ui = nil

local function runtime()
	return GameRT.game()
end

function M.overlay_colour()
	return overlay_colour
end

function M.is_active_flag()
	return active
end

function M.set_active(value)
	active = value == true
end

function M.step_index()
	return step_index
end

function M.set_step_index(index)
	step_index = index
end

function M.reset_step_index()
	step_index = 1
end

function M.bubble_ui()
	return bubble_ui
end

function M.set_bubble_ui(ui)
	bubble_ui = ui
end

function M.settings()
	return runtime() and runtime().SETTINGS
end

function M.from_save()
	local run = runtime() and runtime().RUN
	return run and run.from_save
end

function M.refresh_board_input()
	if runtime().dealt_letters and runtime().dealt_letters.set_ranks then
		runtime().dealt_letters:set_ranks()
	end
	if runtime().pattern_row and runtime().pattern_row.area and runtime().pattern_row.area.set_ranks then
		runtime().pattern_row.area:set_ranks()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

function M.stop_drag()
	local controller = runtime().INPUT
	if not controller or not controller.dragging or not controller.dragging.target then return end
	local target = controller.dragging.target
	if target.stop_drag then
		target:stop_drag()
	elseif controller.release then
		controller:release(target)
	end
end

function M.clear_bubble()
	if bubble_ui and bubble_ui.remove then
		pcall(function() bubble_ui:remove() end)
	end
	bubble_ui = nil
end

function M.mark_complete()
	local s = M.settings()
	if not s then return end
	if not s.first_play_tutorial_force then
		s.first_play_tutorial_complete = true
		if runtime().queue_settings_write then
			runtime():queue_settings_write()
		end
	end
end

function M.try_opening_perk_demo()
	if WORD_GAME_UI.PerkStamp and WORD_GAME_UI.PerkStamp.try_opening_demo then
		WORD_GAME_UI.PerkStamp.try_opening_demo()
	end
end

function M.remove_overlay()
	if runtime().FIRST_PLAY_TUTORIAL_OVERLAY then
		runtime().FIRST_PLAY_TUTORIAL_OVERLAY:remove()
		runtime().FIRST_PLAY_TUTORIAL_OVERLAY = nil
	end
end

return M
