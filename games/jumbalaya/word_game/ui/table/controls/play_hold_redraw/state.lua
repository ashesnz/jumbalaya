--[[ word_game/ui/table/controls/play_hold_redraw/state.lua - Hold-to-redraw session flags ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local Busy = facade.busy()

local M = {}

local hold_t = 0
local holding = false
local block_click = false
local peak_hold_t = 0
local animating = false

function M.hold_t()
	return hold_t
end

function M.set_hold_t(value)
	hold_t = value
end

function M.add_hold_t(dt)
	hold_t = hold_t + dt
end

function M.holding()
	return holding
end

function M.set_holding(value)
	holding = value == true
end

function M.block_click()
	return block_click
end

function M.set_block_click(value)
	block_click = value == true
end

function M.peak_hold_t()
	return peak_hold_t
end

function M.set_peak_hold_t(value)
	peak_hold_t = value
end

function M.is_animating()
	return animating
end

function M.reset_hold()
	holding = false
	hold_t = 0
end

function M.set_animating(on)
	animating = on
	Busy.set("play_hold_redraw_busy", on)
	game_access.patch({ hand_redraw_animating = on and true or false })
end

function M.reset_all()
	M.reset_hold()
	block_click = false
	peak_hold_t = 0
	M.set_animating(false)
end

return M
