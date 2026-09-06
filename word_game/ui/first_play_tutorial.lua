--[[
	word_game/ui/first_play_tutorial.lua - One-time welcome tutorial for new players.

	Full-screen dim with speech bubbles and spotlight steps for the hand,
	placement row, play button, and score slider. Click anywhere to advance.
]]

local CharacterSpeech = require("word_game.ui.character_speech")
local Scheduler = require("app.effects.timeline_scheduler")
local Easing = require("app.effects.easing")

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
	return G and G.SETTINGS
end

function M.is_active()
	return active and G.FIRST_PLAY_TUTORIAL_OVERLAY ~= nil
end

function M.should_show()
	local s = settings()
	if not s then return false end
	if s.first_play_tutorial_force then return true end
	if s.first_play_tutorial_complete then return false end
	return true
end

local function from_save()
	local run = G and G.RUN
	return run and run.from_save
end

local function refresh_board_input()
	if G.hand and G.hand.set_ranks then G.hand:set_ranks() end
	if G.placement_table and G.placement_table.area and G.placement_table.area.set_ranks then
		G.placement_table.area:set_ranks()
	end
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.try_sync()
	end
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.sync_action_buttons then
		WORD_GAME.Sidebar.sync_action_buttons()
	end
end

local function stop_drag()
	local controller = G.INPUT
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
		if G.queue_settings_write then
			G:queue_settings_write()
		end
	end
end

local function try_opening_perk_demo()
	if WORD_GAME and WORD_GAME.PerkStamp and WORD_GAME.PerkStamp.try_opening_demo then
		WORD_GAME.PerkStamp.try_opening_demo()
	end
end

function M.dismiss()
	if not active and not G.FIRST_PLAY_TUTORIAL_OVERLAY then return end
	active = false
	step_index = 1
	clear_bubble()
	if G.FIRST_PLAY_TUTORIAL_OVERLAY then
		G.FIRST_PLAY_TUTORIAL_OVERLAY:remove()
		G.FIRST_PLAY_TUTORIAL_OVERLAY = nil
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
	local room = G.ROOM_ATTACH and G.ROOM_ATTACH.T
	if not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH }
	end
	local room_cx = room.x + room.w * 0.5
	local room_cy = room.y + room.h * 0.5
	return {
		align = "cm",
		offset = { x = cx - room_cx, y = center_y - room_cy },
		major = G.ROOM_ATTACH,
	}
end

local function hand_bubble_config()
	local dealt_hand = require("word_game.ui.dealt_hand")
	dealt_hand.apply_screen_position()

	local hand = G.hand and G.hand.T
	local room = G.ROOM_ATTACH and G.ROOM_ATTACH.T
	if not hand or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH }
	end

	local hand_cx = hand.x + hand.w * 0.5
	local center_y = hand.y - HAND_BUBBLE_GAP - HAND_BUBBLE_HEIGHT * 0.5
	local min_center_y = room.y + HAND_BUBBLE_HEIGHT * 0.5 + 0.08
	center_y = math.max(center_y, min_center_y)

	return room_centered_bubble(hand_cx, center_y)
end

local function placement_bubble_config()
	if G.placement_table and G.placement_table.apply_screen_position then
		G.placement_table:apply_screen_position()
	end

	local area = G.placement_table and G.placement_table.area
	local placement = area and area.T
	local room = G.ROOM_ATTACH and G.ROOM_ATTACH.T
	if not placement or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH }
	end

	local placement_cx = placement.x + placement.w * 0.5
	local center_y = placement.y + placement.h + PLACEMENT_BUBBLE_GAP + PLACEMENT_BUBBLE_HEIGHT * 0.5
	local max_center_y = (G.TILE_H or (room.y + room.h)) - PLACEMENT_BUBBLE_HEIGHT * 0.5 - 0.08
	center_y = math.min(center_y, max_center_y)

	return room_centered_bubble(placement_cx, center_y)
end

local function play_bubble_config()
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.try_sync()
	end

	local bar = G.hand_action_bar
	local btn = WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.play_button_uie()
	local target = (bar and not bar.REMOVED and bar.T) or (btn and btn.T)
	local room = G.ROOM_ATTACH and G.ROOM_ATTACH.T
	if not target or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH }
	end

	local cx = target.x + target.w * 0.5
	local center_y = target.y - PLAY_BUBBLE_GAP - PLAY_BUBBLE_HEIGHT * 0.5
	local min_center_y = room.y + PLAY_BUBBLE_HEIGHT * 0.5 + 0.08
	center_y = math.max(center_y, min_center_y)

	return room_centered_bubble(cx, center_y)
end

local function timeline_bubble_config()
	local Layout = require("word_game.ui.layout")
	local rect = Layout.timeline_rect and Layout.timeline_rect() or Layout.portrait_rect()
	local room = G.ROOM_ATTACH and G.ROOM_ATTACH.T
	if not rect or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH }
	end

	local timeline_cx = rect.x + rect.w * 0.5
	local center_y = rect.y + rect.h + TIMELINE_BUBBLE_GAP + TIMELINE_BUBBLE_HEIGHT * 0.5
	local max_center_y = (G.TILE_H or (room.y + room.h)) - TIMELINE_BUBBLE_HEIGHT * 0.5 - 0.08
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
		major = G.ROOM_ATTACH,
	}
end

local function build_selections(step)
	local selections = { bubble_ui }
	if step.spotlight == "hand" and G.hand then
		selections = { G.hand, bubble_ui }
	end
	return selections
end

local function apply_step()
	local step = STEPS[step_index]
	if not step or not G.FIRST_PLAY_TUTORIAL_OVERLAY then return end

	clear_bubble()

	local bubble_cfg = resolve_bubble_config(step)
	bubble_ui = LayoutView{
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

	G.FIRST_PLAY_TUTORIAL_OVERLAY.selections = build_selections(step)
	G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_hand = step.spotlight == "hand" and true or nil
	G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_placement = step.spotlight == "placement" and true or nil
	G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_play = step.spotlight == "play" and true or nil
	G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_timeline = step.spotlight == "timeline" and true or nil
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
	if G.OVERLAY_MENU then return false end
	local c = G.INPUT
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
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if not G.ROOM_ATTACH then return false end

	active = true
	step_index = 1
	stop_drag()
	G.under_overlay = true

	overlay_colour[4] = 0
	Easing.value{
		ref_table = overlay_colour,
		ref_value = 4,
		mod = 0.72,
		timer = "REAL",
		not_blockable = true,
		delay = 0.4,
	}

	G.FIRST_PLAY_TUTORIAL_OVERLAY = LayoutView{
		definition = {
			n = G.UI.ROOT,
			config = {
				align = "cm",
				padding = 32.05,
				r = 0.1,
				colour = overlay_colour,
				emboss = 0.05,
			},
			nodes = {
				{ n = G.UI.ROW, config = { align = "cm", minh = G.ROOM.T.h, minw = G.ROOM.T.w }, nodes = {} },
			},
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 3.2 },
			major = G.ROOM_ATTACH,
			bond = "Weak",
		},
	}
	G.FIRST_PLAY_TUTORIAL_OVERLAY.flop_overlay = true

	apply_step()
	return true
end

function M.try_schedule()
	if not M.should_show() then return end
	if from_save() then return end
	if G.STATE ~= G.STATES.TABLE_BOARD or G.STAGE ~= G.STAGES.RUN then return end

	Scheduler.add{
		mode = "delayed",
		delay = 0.5,
		blocking = false,
		blockable = false,
		func = function()
			if G.STATE == G.STATES.TABLE_BOARD and G.STAGE == G.STAGES.RUN then
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
		if G.queue_settings_write then
			G:queue_settings_write()
		end
	end
end

function M.set_force(enabled)
	local s = settings()
	if not s then return end
	s.first_play_tutorial_force = enabled and true or false
	if enabled and G.STATE == G.STATES.TABLE_BOARD then
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

G.FUNCS.first_play_tutorial_next = function()
	M.advance()
end

return M
