--[[ word_game/ui/table/controls/play_hold_redraw/init.lua - Hold play button to redraw hand facade ]]

local GameRT = require("word_game.ui.util.game_runtime")
local facade = require("word_game.ui.facade")
local InputLock = facade.input_lock()
local perk_effects = facade.perks_effects()
local button = require("word_game.ui.table.controls.play_hold_redraw.button")
local state = require("word_game.ui.table.controls.play_hold_redraw.state")
local redraw = require("word_game.ui.table.controls.play_hold_redraw.redraw")
local ring = require("word_game.ui.table.controls.play_hold_redraw.ring")

local M = {}

M.HOLD_DURATION = 5.0
M.CLICK_BLOCK = 0.18
M.DISCARD_STAGGER = 0.05
M.RING_WIDTH = 3.5

local function runtime()
	return GameRT.game()
end

local function safe_sound(name, pitch, vol)
	if type(play_sfx) == "function" then
		play_sfx(name, pitch, vol)
	end
end

function M.enabled()
	return perk_effects.hold_redraw_enabled()
end

function M.is_animating()
	return state.is_animating()
end

function M.is_holding()
	return state.holding() and state.hold_t() > 0
end

function M.hold_progress()
	if M.HOLD_DURATION <= 0 then return 0 end
	return math.min(1, state.hold_t() / M.HOLD_DURATION)
end

function M.can_hold()
	if not M.enabled() then return false end
	if state.is_animating() then return false end
	if InputLock.is_table_busy() then return false end
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD then return false end
	if button.gameplay_overlays_active() then return false end
	local btn = button.play_button_uie()
	return btn and btn.states.visible and btn.config.button ~= nil
end

function M.reset()
	state.reset_all()
	if WORD_GAME_UI.TableInput and WORD_GAME_UI.TableInput.refresh_card_input then
		WORD_GAME_UI.TableInput.refresh_card_input()
	else
		if runtime().dealt_letters and runtime().dealt_letters.set_ranks then
			runtime().dealt_letters:set_ranks()
		end
		if runtime().pattern_row and runtime().pattern_row.area and runtime().pattern_row.area.set_ranks then
			runtime().pattern_row.area:set_ranks()
		end
	end
end

function M.consume_click()
	if not M.enabled() then return false end
	if state.block_click() then
		state.set_block_click(false)
		state.set_peak_hold_t(0)
		return true
	end
	if state.peak_hold_t() >= M.CLICK_BLOCK then
		state.set_peak_hold_t(0)
		return true
	end
	return false
end

function M.update(dt)
	if not M.enabled() then return end
	dt = dt or 0

	if button.gameplay_overlays_active() then
		state.reset_hold()
		return
	end

	if state.is_animating() then
		state.reset_hold()
		return
	end

	local c = runtime().INPUT
	local press_state = (c and c.pointer_held) or (love.mouse and love.mouse.isDown and love.mouse.isDown(1))
	if not press_state then
		if state.peak_hold_t() >= M.CLICK_BLOCK then
			state.set_block_click(true)
		end
		state.reset_hold()
		return
	end

	if not M.can_hold() or not button.is_pressing_play() then
		state.reset_hold()
		return
	end

	if not state.holding() and state.hold_t() <= 0 then
		safe_sound("hover_card", 0.85, 0.35)
	end

	state.set_holding(true)
	state.add_hold_t(dt)
	state.set_peak_hold_t(state.hold_t())
	if state.hold_t() >= M.HOLD_DURATION then
		redraw.trigger(M.can_hold, M)
	end
end

function M.draw()
	ring.draw(M.enabled, M)
end

return M
