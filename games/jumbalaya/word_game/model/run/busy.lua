--[[
	word_game/model/run/busy.lua - Table-busy flags (input lock during FX).

	Core: none
	Store: trade_ui_busy, token_reward_busy, card_fly_off_busy, play_hold_redraw_busy
	Presentation: none — InputLock reads flags via game_access.get()
]]

local game_access = require("word_game.model.game_access")

local M = {}

local FLAGS = {
	"trade_ui_busy",
	"token_reward_busy",
	"card_fly_off_busy",
	"play_hold_redraw_busy",
}

function M.set(name, on)
	game_access.dispatch({ type = "SET_BUSY_FLAG", name = name, on = on })
end

function M.on(name)
	local g = game_access.get()
	return g and g[name] == true
end

function M.clear()
	game_access.dispatch({ type = "CLEAR_BUSY_FLAGS", names = FLAGS })
end

return M
