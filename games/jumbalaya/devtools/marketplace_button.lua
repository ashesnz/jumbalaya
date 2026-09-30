--[[
	devtools/marketplace_button.lua - On-screen shortcut to open The Card Marketplace (non-release builds).
]]

local game_runtime = require("devtools.runtime")
local layout = require("devtools.layout")
local Funcs = require("app.callbacks.funcs")

local M = {}

Funcs.register("DT_show_trade", function()
	if WORD_GAME_UI and WORD_GAME_UI.TradeUI and WORD_GAME_UI.TradeUI.open then
		WORD_GAME_UI.TradeUI.open()
	end
end)

local function shell()
	return game_runtime.game()
end

function M.visible()
	if _RELEASE_MODE then
		return false
	end
	local game = shell()
	if not game or not game.STAGES then
		return false
	end
	if game.STAGE == game.STAGES.MAIN_MENU then
		return false
	end
	return true
end

function M.ensure()
	if not M.visible() then
		M.destroy()
		return
	end
	local game = shell()
	if not game or not game.ROOM_ATTACH then
		return
	end
	if game.marketplace_debug_button and not game.marketplace_debug_button.REMOVED then
		return
	end

	local Panels = require("jumbalaya-engine.panels")
	game.marketplace_debug_button = Panels.create({
		definition = {
			n = game.UI.ROOT,
			config = { align = "cm" },
			nodes = {
				layout.button("Market", "show_trade"),
			},
		},
		config = {
			align = "tli",
			offset = { x = 0.35, y = 0.35 },
			major = game.ROOM_ATTACH,
			bond = "Weak",
		},
	})
end

function M.destroy()
	local game = shell()
	if game and game.marketplace_debug_button then
		game.marketplace_debug_button:remove()
		game.marketplace_debug_button = nil
	end
end

function M.sync()
	if M.visible() then
		M.ensure()
	else
		M.destroy()
	end
end

return M
