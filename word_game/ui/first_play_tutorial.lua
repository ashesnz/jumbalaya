--[[
	word_game/ui/first_play_tutorial.lua - One-time welcome tutorial for new players.

	Full-screen dim with a centered speech bubble. Shown once per profile unless
	G.SETTINGS.first_play_tutorial_force is enabled (devtools toggle).
]]

local CharacterSpeech = require("word_game.ui.character_speech")
local Scheduler = require("app.effects.timeline_scheduler")
local Easing = require("app.effects.easing")

local M = {}

local STEPS = {
	"first_play_welcome",
}

local active = false
local step_index = 1
local overlay_colour = { 0.06, 0.08, 0.12, 0 }
local bubble_ui = nil
local button_ui = nil

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

local function clear_ui_refs()
	if bubble_ui and bubble_ui.remove then
		pcall(function() bubble_ui:remove() end)
	end
	if button_ui and button_ui.remove then
		pcall(function() button_ui:remove() end)
	end
	bubble_ui = nil
	button_ui = nil
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
	clear_ui_refs()
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

local function build_step_ui(text_key)
	clear_ui_refs()

	bubble_ui = LayoutView{
		definition = bubble_definition(text_key),
		config = {
			align = "cm",
			offset = { x = 0, y = -0.35 },
			major = G.ROOM_ATTACH,
			bond = "Weak",
		},
	}
	bubble_ui.under_overlay = false
	CharacterSpeech.pop_bubble(bubble_ui)

	local is_last = step_index >= #STEPS
	button_ui = LayoutView{
		definition = {
			n = G.UI.ROOT,
			config = { align = "cm", colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UI.ROW,
					config = {
						align = "cm",
						minh = 0.58,
						minw = 1.6,
						padding = 0.14,
						r = 0.14,
						hover = true,
						colour = G.C.BLUE,
						hover_colour = G.C.FILTER,
						button = "first_play_tutorial_next",
						shadow = true,
						emboss = 0.08,
					},
					nodes = {
						{
							n = G.UI.TEXT,
							config = {
								text = is_last and "Got it!" or "Next",
								scale = 0.34,
								colour = G.C.WHITE,
								shadow = true,
							},
						},
					},
				},
			},
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 1.05 },
			major = G.ROOM_ATTACH,
			bond = "Weak",
		},
	}
	button_ui.under_overlay = false

	if G.FIRST_PLAY_TUTORIAL_OVERLAY then
		G.FIRST_PLAY_TUTORIAL_OVERLAY.selections = { bubble_ui, button_ui }
	end
end

function M.advance()
	if not M.is_active() then return end
	if step_index < #STEPS then
		step_index = step_index + 1
		build_step_ui(STEPS[step_index])
		play_sfx("cancel", 0.85, 0.55)
		return
	end
	M.dismiss()
	play_sfx("cancel", 0.9, 0.6)
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

	build_step_ui(STEPS[step_index])
	refresh_board_input()
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
