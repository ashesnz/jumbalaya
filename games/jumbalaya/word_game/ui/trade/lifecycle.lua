--[[ word_game/ui/trade/lifecycle.lua - Open and close the marketplace overlay ]]

local game = require("word_game.ui.util.game_runtime").game
local Funcs = require("app.callbacks.funcs")

local facade = require("word_game.ui.facade")
local Play = facade.jumble_play()
local session_state = require("word_game.ui.trade.session_state")
local offer = require("word_game.ui.trade.offer")
local trade_layout = require("word_game.ui.trade.layout")

local M = {}

local host

function M.bind(trade_host)
	host = trade_host
end

local function dismiss_debug_panel()
	local g = game()
	if not g then
		return
	end
	if g.debug_panel and g.debug_panel.is_open and g.debug_panel:is_open() then
		g.debug_panel:close()
		return
	end
	if g.debug_tools and not g.debug_tools.REMOVED then
		g.debug_tools:remove()
		g.debug_tools = nil
	end
end

function M.close()
	local was_standalone = session_state.is_standalone()
	session_state.teardown()
	game().SETTINGS.paused = false
	if Funcs.get("close_overlay") then
		Funcs.dispatch("close_overlay")
	end
	if not was_standalone then
		Play.continue_after_dealer()
	end
end

function M.open_overlay()
	dismiss_debug_panel()
	offer.prepare()
	game().SETTINGS.paused = true
	if WORD_GAME_UI.PlayHoldRedraw and WORD_GAME_UI.PlayHoldRedraw.reset then
		WORD_GAME_UI.PlayHoldRedraw.reset()
	end
	Funcs.dispatch("show_overlay", {
		definition = host.definition(),
		config = {
			no_esc = true,
			offset = trade_layout.modal_overlay_offset(),
			no_jiggle = true,
		},
	})
end

function M.open_standalone()
	session_state.mark_open(true)
	M.open_overlay()
end

function M.open_then_dealer()
	local rs = facade.run_state().get()
	local trade_model = facade.trade()
	if (rs and rs.trade_used_this_hand) or not trade_model.can_use() then
		session_state.teardown()
		Play.continue_after_dealer()
		return
	end
	session_state.mark_open(false)
	M.open_overlay()
end

return M
