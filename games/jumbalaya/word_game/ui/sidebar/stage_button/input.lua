--[[ word_game/ui/sidebar/stage_button/input.lua - Click hit-test and press actions ]]

local GameRT = require("word_game.ui.util.game_runtime")
local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local table_discard = require("word_game.ui.perks.discard_bin")
local action_dispatch = require("app.input.action_dispatch")
local Funcs = require("app.callbacks.funcs")
local state = require("word_game.ui.sidebar.stage_button.state")
local animate = require("word_game.ui.sidebar.stage_button.animate")

local M = {}

local function runtime()
	return GameRT.game()
end

local function widget()
	return state.widget()
end

local function input_lock()
	return facade.input_lock()
end

local function play()
	return facade.jumble_play()
end

local function pointer_tile()
	if not runtime() or not runtime().POINTER or not runtime().POINTER.T then return nil, nil end
	return runtime().POINTER.T.x, runtime().POINTER.T.y
end

function M.point_in_button(rect, tx, ty)
	local w = widget()
	if not rect or not w.visible then return false end
	tx, ty = tx or pointer_tile()
	if not tx or not ty then return false end
	local attach = runtime().SIDEBAR_ATTACH and runtime().SIDEBAR_ATTACH.T
	if not attach then return false end
	local x = attach.x + rect.x
	local y = attach.y + rect.y
	return tx >= x and tx <= x + rect.w and ty >= y and ty <= y + rect.h
end

local function commit_pending_score()
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	if not j then return 0 end
	local pending = 0
	if (j.puzzle_points or 0) > 0 then
		pending = math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1))
	end
	if pending > 0 then
		j.total_score = (j.total_score or 0) + pending
		j.puzzle_points = 0
		j.puzzle_multi = 1.0
		j.puzzle_words = {}
		j.solved = false
	end
	return j.total_score or 0
end

function M.collect_and_advance()
	local w = widget()
	if not animate.is_next_mode() and w.mode ~= "next" then return false end
	if input_lock().is_table_busy() then return false end
	local token_reward = WORD_GAME_UI.TokenReward
	if token_reward and token_reward.is_active and token_reward.is_active() then
		return false
	end

	local amount = commit_pending_score()
	if amount <= 0 then return false end

	if play().on_hand_cleared then
		play().on_hand_cleared()
	end
	return true
end

function M.press()
	local w = widget()
	if animate.is_next_mode() or w.mode == "next" then
		return M.collect_and_advance()
	end
	return table_discard.end_run()
end

function M.consume_click(mx, my, rect)
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD then return false end
	if runtime().OVERLAY_MENU then return false end
	local w = widget()
	if not w.visible then return false end
	if not M.point_in_button(rect, mx, my) then return false end
	local action = w.button_action
	if action and Funcs.get(action) then
		action_dispatch.dispatch_func(action)
		Funcs.dispatch(action)
		return true
	end
	return M.press()
end

return M
