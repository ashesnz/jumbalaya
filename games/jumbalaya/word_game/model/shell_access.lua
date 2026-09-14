--[[
	word_game/model/shell_access.lua - Canonical read/write accessors for the Game shell.

	Run snapshot fields belong on game_access / WORD_GAME.store() — not here.
	Do not assign live_game().field or game().field outside this module (except
	Game bootstrap in model/game/*).
]]

local live_game = require("word_game.model.live_game")
local table_areas = require("word_game.model.table_areas")

local M = {}

function M.raw()
	return live_game()
end

-- ============ Letter registry ============

function M.letter_inventory()
	local g = live_game()
	return g and g.letter_inventory
end

function M.ensure_letter_inventory()
	local g = live_game()
	g.letter_inventory = g.letter_inventory or {}
	return g.letter_inventory
end

function M.set_letter_inventory(list)
	live_game().letter_inventory = list
end

function M.letter_card_id()
	local g = live_game()
	return g and g.letter_card_id
end

function M.set_letter_card_id(id)
	live_game().letter_card_id = id
end

function M.next_letter_card_id()
	local g = live_game()
	g.letter_card_id = (g.letter_card_id or 0) + 1
	return g.letter_card_id
end

function M.reset_letter_registry()
	local g = live_game()
	g.letter_inventory = {}
	g.letter_card_id = 0
end

function M.next_sort_id()
	local g = live_game()
	g.sort_id = (g.sort_id or 0) + 1
	return g.sort_id
end

-- ============ CardPile hosts (read via table_areas) ============

function M.dealt_letters()
	return table_areas.dealt_letters()
end

function M.draw_pile()
	return table_areas.draw_pile()
end

function M.recycle_stash()
	return table_areas.recycle_stash()
end

function M.pattern_row()
	return table_areas.pattern_row()
end

function M.pattern_row_area()
	return table_areas.pattern_row_area()
end

-- ============ Transient overlay / draw shell flags ============

function M.set_under_overlay(on)
	live_game().under_overlay = on and true or false
end

function M.set_shared_shadow(node)
	live_game().shared_shadow = node
end

function M.set_last_materialized(time)
	live_game().last_materialized = time
end

function M.set_main_menu_logo_applied_scale(scale)
	live_game().main_menu_logo_applied_scale = scale
end

-- ============ Menu profile selection (shell-only, not run state) ============

function M.focused_profile()
	local g = live_game()
	return g and g.focused_profile
end

function M.ensure_focused_profile(default)
	local g = live_game()
	g.focused_profile = g.focused_profile or default or 1
	return g.focused_profile
end

function M.set_focused_profile(profile)
	live_game().focused_profile = profile
end

-- ============ Table control bars ============

function M.set_table_control_bars(shuffle_bar, play_bar)
	local g = live_game()
	g.table_shuffle_bar = shuffle_bar
	g.hand_action_bar = play_bar
	g.table_shuffle_button = shuffle_bar
	g.hand_play_button = play_bar
	g.PLAY_WORD_UI = play_bar
end

function M.clear_table_control_bars()
	local g = live_game()
	g.table_shuffle_bar = nil
	g.hand_action_bar = nil
	g.table_shuffle_button = nil
	g.hand_play_button = nil
	g.PLAY_WORD_UI = nil
end

function M.destroy_table_control_bars()
	local g = live_game()
	if g.table_shuffle_bar then
		g.table_shuffle_bar:remove()
	end
	if g.hand_action_bar then
		g.hand_action_bar:remove()
	end
	M.clear_table_control_bars()
end

function M.set_args_field(key, value)
	local g = live_game()
	g.ARGS = g.ARGS or {}
	g.ARGS[key] = value
end

function M.clear_args_field(key)
	local g = live_game()
	if g.ARGS then
		g.ARGS[key] = nil
	end
end

-- ============ ARGS queues ============

function M.word_feedback_queue()
	local g = live_game()
	local args = g and g.ARGS
	return args and args.word_feedback_queue
end

function M.set_word_feedback_queue(queue)
	M.set_args_field("word_feedback_queue", queue)
end

function M.clear_word_feedback_queue()
	M.clear_args_field("word_feedback_queue")
end

return M
