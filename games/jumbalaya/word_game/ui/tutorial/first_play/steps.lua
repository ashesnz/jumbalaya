--[[ word_game/ui/tutorial/first_play/steps.lua - Apply spotlight steps to the overlay ]]

local game = require("word_game.ui.util.game_runtime").game
local CharacterSpeech = require("word_game.ui.tutorial.character_speech")
local UIViewHost = require("jumbalaya-engine.panels.view_host")
local config = require("word_game.ui.tutorial.first_play.config")
local session = require("word_game.ui.tutorial.first_play.session")
local layout = require("word_game.ui.tutorial.first_play.layout")

local M = {}


local function build_selections(step, bubble_ui)
	local selections = { bubble_ui }
	if step.spotlight == "hand" and game().dealt_letters then
		selections = { game().dealt_letters, bubble_ui }
	end
	return selections
end

function M.apply_current()
	local step = config.STEPS[session.step_index()]
	if not step or not game().FIRST_PLAY_TUTORIAL_OVERLAY then return end

	session.clear_bubble()

	local bubble_cfg = layout.resolve_bubble_config(step)
	local bubble_ui = UIViewHost.create{
		definition = layout.bubble_definition(step.key),
		config = {
			align = bubble_cfg.align,
			offset = bubble_cfg.offset,
			major = bubble_cfg.major,
			bond = "Weak",
		},
	}
	bubble_ui.flop_overlay = true
	bubble_ui.under_overlay = false
	session.set_bubble_ui(bubble_ui)
	CharacterSpeech.pop_bubble(bubble_ui)

	local overlay = game().FIRST_PLAY_TUTORIAL_OVERLAY
	overlay.selections = build_selections(step, bubble_ui)
	overlay.redraw_hand = step.spotlight == "hand" and true or nil
	overlay.redraw_placement = step.spotlight == "placement" and true or nil
	overlay.redraw_play = step.spotlight == "play" and true or nil
	overlay.redraw_timeline = step.spotlight == "timeline" and true or nil
	session.refresh_board_input()
end

function M.advance_or_finish(dismiss_fn)
	if session.step_index() < #config.STEPS then
		session.set_step_index(session.step_index() + 1)
		M.apply_current()
		play_sfx("cancel", 0.85, 0.55)
		return false
	end
	dismiss_fn()
	play_sfx("cancel", 0.9, 0.6)
	return true
end

return M
