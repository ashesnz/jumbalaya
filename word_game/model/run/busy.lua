--[[ word_game/model/run/busy.lua - Model-side table-busy flags on G.GAME (set by FX modules) ]]

local M = {}

local FLAGS = {
	"trade_ui_busy",
	"token_reward_busy",
	"card_fly_off_busy",
	"play_hold_redraw_busy",
}

function M.set(name, on)
	if not G or not G.GAME then return end
	G.GAME[name] = on and true or nil
end

function M.on(name)
	return G and G.GAME and G.GAME[name] == true
end

function M.clear()
	if not G or not G.GAME then return end
	for _, name in ipairs(FLAGS) do
		G.GAME[name] = nil
	end
end

return M
