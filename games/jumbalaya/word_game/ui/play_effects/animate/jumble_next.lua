--[[ word_game/ui/play_effects/animate/jumble_next.lua - Puzzle advance animation ]]

local GameRT = require("word_game.ui.util.game_runtime")
local jumble_fixed_letters = require("word_game.ui.table.jumble_fixed_letters")
local Easing = require "word_game.ui.effects.easing"
local definition = require("word_game.ui.play_effects.definition")
local context = require("word_game.ui.play_effects.animate.context")

local M = {}

local function runtime()
	return GameRT.game()
end

local function has_event_manager()
	return runtime().TIMELINE and runtime().TIMELINE.enqueue
end

function M.present_jumble_next(jumble, wr, opts)
	local jl = jumble_fixed_letters
	definition.set_word_score_animating(true)
	if play_sfx then play_sfx("card_slide1", 0.85, 0.7) end

	local anim = jl.anim_state()
	if has_event_manager() and not (opts and opts.instant) then
		jl.set_anim({ offset_y = 0, alpha = 1 })
		Easing.value{ref_table = anim, ref_value = "offset_y", mod = -4.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}
		Easing.value{ref_table = anim, ref_value = "alpha", mod = -1.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}

		context.effects().queue_event(Tween({
			mode = "delayed",
			delay = 0.24,
			blocking = true,
			func = function()
				jumble.advance_puzzle(wr)
				jl.set_anim({ offset_y = 4.0, alpha = 0 })
				Easing.value{ref_table = anim, ref_value = "offset_y", mod = -4.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}
				Easing.value{ref_table = anim, ref_value = "alpha", mod = 1.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}
				if play_sfx then play_sfx("card_slide1", 1.05, 0.7) end
				return true
			end,
		}))

		context.effects().queue_event(Tween({
			mode = "delayed",
			delay = 0.24,
			blocking = true,
			func = function()
				jl.reset_anim()
				definition.set_word_score_animating(false)
				definition.sync_hand_controls()
				if opts and opts.on_complete then
					opts.on_complete()
				end
				return true
			end,
		}))
	else
		jumble.advance_puzzle(wr)
		jl.reset_anim()
		definition.set_word_score_animating(false)
		if opts and opts.on_complete then
			opts.on_complete()
		end
	end
end

function M.present_end_jumble_sidebar()
	definition.sync_hand_controls()
	if WORD_GAME_UI.Sidebar then
		WORD_GAME_UI.Sidebar:refresh()
	end
end

return M
