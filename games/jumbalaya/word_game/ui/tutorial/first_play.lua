--[[
	word_game/ui/tutorial/first_play.lua - One-time welcome tutorial for new players.

	Full-screen dim with speech bubbles and spotlight steps for the hand,
	placement row, play button, and score slider. Click anywhere to advance.
]]


local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local CharacterSpeech = require("word_game.ui.tutorial.character_speech")
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local Easing = require("word_game.ui.effects.easing")
local dealt_hand = require("word_game.ui.table.dealt_hand")
local Layout = require("word_game.ui.layout")
local UIViewHost = require("jumbalaya-engine.panels.view_host")

local M = {}

local STEPS = {
	{
		key = "first_play_welcome",
		spotlight = nil,
		bubble = { align = "cm", offset = { x = 0, y = -0.35 }, major = "room" },
	},
	{
		key = "first_play_hand",
		spotlight = "hand",
		bubble = { layout = "hand" },
	},
	{
		key = "first_play_placement",
		spotlight = "placement",
		bubble = { layout = "placement" },
	},
	{
		key = "first_play_positions",
		spotlight = "placement",
		bubble = { layout = "placement" },
	},
	{
		key = "first_play_play_button",
		spotlight = "play",
		bubble = { layout = "play" },
	},
	{
		key = "first_play_goal",
		spotlight = "timeline",
		bubble = { layout = "timeline" },
	},
}

local HAND_BUBBLE_GAP = 0.12
local HAND_BUBBLE_HEIGHT = 0.9
local PLACEMENT_BUBBLE_GAP = 0.14
local PLACEMENT_BUBBLE_HEIGHT = 1.1
local PLAY_BUBBLE_GAP = 0.12
local PLAY_BUBBLE_HEIGHT = 1.15
local TIMELINE_BUBBLE_GAP = 0.14
local TIMELINE_BUBBLE_HEIGHT = 0.85

local active = false
local step_index = 1
local overlay_colour = { 0.06, 0.08, 0.12, 0 }
local bubble_ui = nil

local function settings()
	return runtime() and runtime().SETTINGS
end

function M.is_active()
	return active and runtime().FIRST_PLAY_TUTORIAL_OVERLAY ~= nil
end

function M.should_show()
	if runtime() and runtime().F_SKIP_TUTORIAL then return false end
	local s = settings()
	if not s then return false end
	if s.first_play_tutorial_force then return true end
	if s.first_play_tutorial_complete then return false end
	return true
end

local function from_save()
	local run = runtime() and runtime().RUN
	return run and run.from_save
end

local function refresh_board_input()
	if runtime().dealt_letters and runtime().dealt_letters.set_ranks then runtime().dealt_letters:set_ranks() end
	if runtime().pattern_row and runtime().pattern_row.area and runtime().pattern_row.area.set_ranks then
		runtime().pattern_row.area:set_ranks()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

local function stop_drag()
	local controller = runtime().INPUT
	if not controller or not controller.dragging or not controller.dragging.target then return end
	local target = controller.dragging.target
	if target.stop_drag then
		target:stop_drag()
	elseif controller.release then
		controller:release(target)
	end
end

local function clear_bubble()
	if bubble_ui and bubble_ui.remove then
		pcall(function() bubble_ui:remove() end)
	end
	bubble_ui = nil
end

local function mark_complete()
	local s = settings()
	if not s then return end
	if not s.first_play_tutorial_force then
		s.first_play_tutorial_complete = true
		if runtime().queue_settings_write then
			runtime():queue_settings_write()
		end
	end
end

local function try_opening_perk_demo()
	if WORD_GAME_UI.PerkStamp and WORD_GAME_UI.PerkStamp.try_opening_demo then
		WORD_GAME_UI.PerkStamp.try_opening_demo()
	end
end

function M.dismiss()
	if not active and not runtime().FIRST_PLAY_TUTORIAL_OVERLAY then return end
	active = false
	step_index = 1
	clear_bubble()
	if runtime().FIRST_PLAY_TUTORIAL_OVERLAY then
		runtime().FIRST_PLAY_TUTORIAL_OVERLAY:remove()
		runtime().FIRST_PLAY_TUTORIAL_OVERLAY = nil
	end
	mark_complete()
	refresh_board_input()
	try_opening_perk_demo()
end

local function bubble_definition(text_key)
	local def = CharacterSpeech.bubble_definition(text_key)
	if def and def.config then
		def.config.speech_tail = nil
	end
	return def
end

local function room_centered_bubble(cx, center_y)
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end
	local room_cx = room.x + room.w * 0.5
	local room_cy = room.y + room.h * 0.5
	return {
		align = "cm",
		offset = { x = cx - room_cx, y = center_y - room_cy },
		major = runtime().ROOM_ATTACH,
	}
end

local function hand_bubble_config()
	dealt_hand.apply_screen_position()

	local hand = runtime().dealt_letters and runtime().dealt_letters.T
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not hand or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local hand_cx = hand.x + hand.w * 0.5
	local center_y = hand.y - HAND_BUBBLE_GAP - HAND_BUBBLE_HEIGHT * 0.5
	local min_center_y = room.y + HAND_BUBBLE_HEIGHT * 0.5 + 0.08
	center_y = math.max(center_y, min_center_y)

	return room_centered_bubble(hand_cx, center_y)
end

local function placement_bubble_config()
	if runtime().pattern_row and runtime().pattern_row.apply_screen_position then
		runtime().pattern_row:apply_screen_position()
	end

	local area = runtime().pattern_row and runtime().pattern_row.area
	local placement = area and area.T
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not placement or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local placement_cx = placement.x + placement.w * 0.5
	local center_y = placement.y + placement.h + PLACEMENT_BUBBLE_GAP + PLACEMENT_BUBBLE_HEIGHT * 0.5
	local max_center_y = (runtime().TILE_H or (room.y + room.h)) - PLACEMENT_BUBBLE_HEIGHT * 0.5 - 0.08
	center_y = math.min(center_y, max_center_y)

	return room_centered_bubble(placement_cx, center_y)
end

local function play_bubble_config()
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end

	local bar = runtime().hand_action_bar
	local btn = WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.play_button_uie()
	local target = (bar and not bar.REMOVED and bar.T) or (btn and btn.T)
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not target or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local cx = target.x + target.w * 0.5
	local center_y = target.y - PLAY_BUBBLE_GAP - PLAY_BUBBLE_HEIGHT * 0.5
	local min_center_y = room.y + PLAY_BUBBLE_HEIGHT * 0.5 + 0.08
	center_y = math.max(center_y, min_center_y)

	return room_centered_bubble(cx, center_y)
end

local function timeline_bubble_config()
	local rect = Layout.timeline_rect and Layout.timeline_rect() or Layout.portrait_rect()
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not rect or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local timeline_cx = rect.x + rect.w * 0.5
	local center_y = rect.y + rect.h + TIMELINE_BUBBLE_GAP + TIMELINE_BUBBLE_HEIGHT * 0.5
	local max_center_y = (runtime().TILE_H or (room.y + room.h)) - TIMELINE_BUBBLE_HEIGHT * 0.5 - 0.08
	center_y = math.min(center_y, max_center_y)

	return room_centered_bubble(timeline_cx, center_y)
end

local function resolve_bubble_config(step)
	if step.bubble.layout == "hand" then
		return hand_bubble_config()
	end
	if step.bubble.layout == "placement" then
		return placement_bubble_config()
	end
	if step.bubble.layout == "play" then
		return play_bubble_config()
	end
	if step.bubble.layout == "timeline" then
		return timeline_bubble_config()
	end
	return {
		align = step.bubble.align,
		offset = step.bubble.offset,
		major = runtime().ROOM_ATTACH,
	}
end

local function build_selections(step)
	local selections = { bubble_ui }
	if step.spotlight == "hand" and runtime().dealt_letters then
		selections = { runtime().dealt_letters, bubble_ui }
	end
	return selections
end

local function apply_step()
	local step = STEPS[step_index]
	if not step or not runtime().FIRST_PLAY_TUTORIAL_OVERLAY then return end

	clear_bubble()

	local bubble_cfg = resolve_bubble_config(step)
	bubble_ui = UIViewHost.create{
		definition = bubble_definition(step.key),
		config = {
			align = bubble_cfg.align,
			offset = bubble_cfg.offset,
			major = bubble_cfg.major,
			bond = "Weak",
		},
	}
	bubble_ui.flop_overlay = true
	bubble_ui.under_overlay = false
	CharacterSpeech.pop_bubble(bubble_ui)

	runtime().FIRST_PLAY_TUTORIAL_OVERLAY.selections = build_selections(step)
	runtime().FIRST_PLAY_TUTORIAL_OVERLAY.redraw_hand = step.spotlight == "hand" and true or nil
	runtime().FIRST_PLAY_TUTORIAL_OVERLAY.redraw_placement = step.spotlight == "placement" and true or nil
	runtime().FIRST_PLAY_TUTORIAL_OVERLAY.redraw_play = step.spotlight == "play" and true or nil
	runtime().FIRST_PLAY_TUTORIAL_OVERLAY.redraw_timeline = step.spotlight == "timeline" and true or nil
	refresh_board_input()
end

function M.advance()
	if not M.is_active() then return end
	if step_index < #STEPS then
		step_index = step_index + 1
		apply_step()
		play_sfx("cancel", 0.85, 0.55)
		return
	end
	M.dismiss()
	play_sfx("cancel", 0.9, 0.6)
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
	if active then return false end
	if not M.should_show() then return false end
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD then return false end
	if not runtime().ROOM_ATTACH then return false end

	active = true
	step_index = 1
	stop_drag()
	runtime().under_overlay = true

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

	apply_step()
	return true
end

function M.try_schedule()
	if not M.should_show() then return end
	if from_save() then return end
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
	local s = settings()
	if s then
		s.first_play_tutorial_complete = false
		if runtime().queue_settings_write then
			runtime():queue_settings_write()
		end
	end
end

function M.set_force(enabled)
	local s = settings()
	if not s then return end
	s.first_play_tutorial_force = enabled and true or false
	if enabled and runtime().STATE == runtime().STATES.TABLE_BOARD then
		M.begin()
	elseif not enabled and M.is_active() then
		M.dismiss()
	end
end

function M.toggle_force()
	local s = settings()
	if not s then return false end
	local next = not s.first_play_tutorial_force
	M.set_force(next)
	return next
end

function M.force_status_label()
	local s = settings()
	return (s and s.first_play_tutorial_force) and "ON" or "OFF"
end

return M
