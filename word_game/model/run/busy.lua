--[[ word_game/model/run/busy.lua - Model-side table-busy flags written by the game layer ]]

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

--- Snapshot UI animation queries onto G.GAME. Called from game_boot, not model.
function M.sync_from_ui(ui)
	ui = ui or rawget(_G, "WORD_GAME_UI")
	if not ui then
		M.clear()
		return
	end
	local trade = ui.TradeUI
	local trade_busy = trade
		and ((trade.is_flying and trade.is_flying()) or (trade.is_transforming and trade.is_transforming()))
	M.set("trade_ui_busy", trade_busy)
	local reward = ui.TokenReward
	M.set("token_reward_busy", reward and reward.is_active and reward.is_active())
	local fly = ui.CardFlyOff
	M.set("card_fly_off_busy", fly and fly.is_active and fly.is_active())
	local hold = ui.PlayHoldRedraw
	M.set("play_hold_redraw_busy", hold and hold.is_animating and hold.is_animating())
end

return M
