--[[ word_game/ui/tutorial/first_play/init.lua - One-time welcome tutorial facade ]]

local GameRT = require("word_game.ui.util.game_runtime")
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local Easing = require("word_game.ui.effects.easing")
local UIViewHost = require("jumbalaya-engine.panels.view_host")
local session = require("word_game.ui.tutorial.first_play.session")
local steps = require("word_game.ui.tutorial.first_play.steps")

local M = {}

local function runtime()
	return GameRT.game()
end

function M.is_active()
	return session.is_active_flag() and runtime().FIRST_PLAY_TUTORIAL_OVERLAY ~= nil
end

function M.should_show()
	if runtime() and runtime().F_SKIP_TUTORIAL then return false end
	local s = session.settings()
	if not s then return false end
	if s.first_play_tutorial_force then return true end
	if s.first_play_tutorial_complete then return false end
	return true
end

function M.dismiss()
	if not session.is_active_flag() and not runtime().FIRST_PLAY_TUTORIAL_OVERLAY then return end
	session.set_active(false)
	session.reset_step_index()
	session.clear_bubble()
	session.remove_overlay()
	session.mark_complete()
	session.refresh_board_input()
	session.try_opening_perk_demo()
end

function M.advance()
	if not M.is_active() then return end
	steps.advance_or_finish(M.dismiss)
end

function M.consume_click()
	if not M.is_active() then return false end
	if runtime().OVERLAY_MENU then return false end
	local c = runtime().INPUT
	if not c or c.clicked.handled then return false end
	if c.dragging.prev_target and Card and getmetatable(c.dragging.prev_target) == Card then
		return false
	end
	M.advance()
	return true
end

function M.begin()
	if session.is_active_flag() then return false end
	if not M.should_show() then return false end
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD then return false end
	if not runtime().ROOM_ATTACH then return false end

	session.set_active(true)
	session.reset_step_index()
	session.stop_drag()
	runtime().under_overlay = true

	local overlay_colour = session.overlay_colour()
	overlay_colour[4] = 0
	Easing.value{
		ref_table = overlay_colour,
		ref_value = 4,
		mod = 0.72,
		timer = "REAL",
		not_blockable = true,
		delay = 0.4,
	}

	runtime().FIRST_PLAY_TUTORIAL_OVERLAY = UIViewHost.create{
		definition = {
			n = runtime().UI.ROOT,
			config = {
				align = "cm",
				padding = 32.05,
				r = 0.1,
				colour = overlay_colour,
				emboss = 0.05,
			},
			nodes = {
				{ n = runtime().UI.ROW, config = { align = "cm", minh = runtime().ROOM.T.h, minw = runtime().ROOM.T.w }, nodes = {} },
			},
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 3.2 },
			major = runtime().ROOM_ATTACH,
			bond = "Weak",
		},
	}
	runtime().FIRST_PLAY_TUTORIAL_OVERLAY.flop_overlay = true

	steps.apply_current()
	return true
end

function M.try_schedule()
	if not M.should_show() then return end
	if session.from_save() then return end
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD or runtime().STAGE ~= runtime().STAGES.RUN then return end

	Scheduler.add{
		mode = "delayed",
		delay = 0.5,
		blocking = false,
		blockable = false,
		func = function()
			if runtime().STATE == runtime().STATES.TABLE_BOARD and runtime().STAGE == runtime().STAGES.RUN then
				M.begin()
			end
			return true
		end,
	}
end

function M.reset()
	M.dismiss()
	local s = session.settings()
	if s then
		s.first_play_tutorial_complete = false
		if runtime().queue_settings_write then
			runtime():queue_settings_write()
		end
	end
end

function M.set_force(enabled)
	local s = session.settings()
	if not s then return end
	s.first_play_tutorial_force = enabled and true or false
	if enabled and runtime().STATE == runtime().STATES.TABLE_BOARD then
		M.begin()
	elseif not enabled and M.is_active() then
		M.dismiss()
	end
end

function M.toggle_force()
	local s = session.settings()
	if not s then return false end
	local next = not s.first_play_tutorial_force
	M.set_force(next)
	return next
end

function M.force_status_label()
	local s = session.settings()
	return (s and s.first_play_tutorial_force) and "ON" or "OFF"
end

return M
