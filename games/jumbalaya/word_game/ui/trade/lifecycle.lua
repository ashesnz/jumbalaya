--[[ word_game/ui/trade/lifecycle.lua - Overlay open, rebuild, refresh, and close ]]

local game = require("word_game.ui.util.game_runtime").game
local Funcs = require("app.callbacks.funcs")

local facade = require("word_game.ui.facade")
local Play = facade.jumble_play()
local trade_layout = require("word_game.ui.trade.layout")
local trade_fly = require("word_game.ui.trade.fly")
local trade_definition = require("word_game.ui.trade.definition")
local trade_animate = require("word_game.ui.trade.animate")
local session_state = require("word_game.ui.trade.session_state")
local affordability = require("word_game.ui.trade.affordability")
local views_install = require("word_game.ui.views.install")
local TradeView = require("word_game.ui.views.trade_view")

local M = {}

local host

local modal_offset_y = trade_layout.modal_offset_y
local modal_minh = trade_layout.modal_minh

function M.bind(trade_host)
	host = trade_host
end


function M.def_ctx()
	return {
		host = host,
		get_offer = session_state.offer,
		get_session = session_state.session,
		modal_minh = modal_minh,
	}
end

local function close_menu()
	session_state.teardown()
	trade_fly.clear()
	trade_animate.clear()
	if Funcs.get("close_overlay") then
		Funcs.dispatch("close_overlay")
	end
end

local function continue_run()
	session_state.teardown()
	if Funcs.get("close_overlay") then
		Funcs.dispatch("close_overlay")
	end
	Play.continue_after_dealer()
end

function M.finish_trade()
	facade.trade().mark_used()
	if session_state.is_standalone() then
		session_state.set_standalone(false)
		close_menu()
		return
	end
	continue_run()
end

function M.open_overlay()
	local shell = require("app.runtime")
	local engine = shell.engine()
	if engine then
		views_install.install_trade(engine)
	end
	game().SETTINGS.paused = true
	if WORD_GAME_UI.PlayHoldRedraw and WORD_GAME_UI.PlayHoldRedraw.reset then
		WORD_GAME_UI.PlayHoldRedraw.reset()
	end
	Funcs.dispatch("show_overlay", {
		definition = host.definition(),
		config = { no_esc = true, offset = { x = 0, y = modal_offset_y() }, no_jiggle = true },
	})
end

function M.rebuild_overlay()
	if not game().OVERLAY_MENU then
		M.open_overlay()
		return
	end
	local menu_host = game().OVERLAY_MENU:find_node_by_id("trade_marketplace_body")
	if not menu_host or not menu_host.config then
		M.open_overlay()
		return
	end
	local prev_body_h = nil
	if menu_host.config.object and menu_host.config.object.VT and menu_host.config.object.VT.h then
		prev_body_h = menu_host.config.object.VT.h
	end
	if menu_host.config.object and menu_host.config.object.remove then
		menu_host.config.object:remove()
	end
	local body_ctx = M.def_ctx()
	local body_def = trade_definition.marketplace_body_definition(body_ctx)
	if prev_body_h and body_def.config then
		body_def.config.minh = math.max(body_def.config.minh or 0, prev_body_h)
	end
	menu_host.config.object = TradeView.create_marketplace_body(body_ctx, {
		offset = { x = 0, y = 0 },
		align = "cm",
		parent = menu_host,
	}, body_def)
	game().OVERLAY_MENU:recalculate()
end

function M.refresh_overlay()
	if affordability.cannot_afford_anything(session_state.offer(), session_state.session()) then
		M.finish_trade()
		return
	end
	M.rebuild_overlay()
end

function M.refresh_or_finish()
	if session_state.session_complete() then
		M.finish_trade()
		return
	end
	M.refresh_overlay()
end

function M.open_standalone()
	session_state.set_standalone(true)
	session_state.reset(facade.trade().roll_offer())
	if affordability.cannot_afford_anything(session_state.offer(), session_state.session()) then
		M.finish_trade()
		return
	end
	M.open_overlay()
end

function M.open_then_dealer()
	session_state.set_standalone(false)
	local rs = facade.run_state().get()
	local trade_model = facade.trade()
	if (rs and rs.trade_used_this_hand) or not trade_model.can_use() then
		continue_run()
		return
	end
	session_state.reset(trade_model.roll_offer())
	if affordability.cannot_afford_anything(session_state.offer(), session_state.session()) then
		M.finish_trade()
		return
	end
	M.open_overlay()
end

return M
