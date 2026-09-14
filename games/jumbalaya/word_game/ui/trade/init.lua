--[[ word_game/ui/trade/init.lua - Card Marketplace overlay facade ]]

local trade_layout = require("word_game.ui.trade.layout")
local trade_fly = require("word_game.ui.trade.fly")
local trade_definition = require("word_game.ui.trade.definition")
local trade_draw = require("word_game.ui.trade.draw")
local trade_animate = require("word_game.ui.trade.animate")
local session_state = require("word_game.ui.trade.session_state")
local affordability = require("word_game.ui.trade.affordability")
local lifecycle = require("word_game.ui.trade.lifecycle")
local handlers = require("word_game.ui.trade.handlers")

local facade = require("word_game.ui.facade")

local M = {}

local room_translate = trade_layout.room_translate

lifecycle.bind(M)

trade_animate.init({
	refresh_overlay = lifecycle.refresh_overlay,
	finish_trade = lifecycle.finish_trade,
	broke_after_last_action = session_state.broke_after_last_action,
	get_offer = session_state.offer,
	get_session = session_state.session,
})

function M.session_add_cost(session_state)
	return affordability.session_add_cost(session_state)
end

function M.can_afford_action(action, session_state)
	return affordability.can_afford_action(action, session_state)
end

function M.is_action_disabled(action, item, session_state)
	return affordability.is_action_disabled(action, item, session_state)
end

function M.cannot_afford_anything(opts)
	return affordability.cannot_afford_anything(session_state.offer(), session_state.session(), opts)
end

function M.definition()
	if not session_state.offer() then
		session_state.reset(facade.trade().roll_offer())
	elseif not session_state.session() then
		session_state.reset(session_state.offer())
	end
	return trade_definition.build_overlay_definition(lifecycle.def_ctx())
end

function M.is_flying()
	return trade_fly.is_flying()
end

function M.is_open()
	return session_state.offer() ~= nil
end

function M.step_card_fly(dt)
	return trade_fly.step_card_fly(dt)
end

function M.backdrop_pass()
	trade_draw.backdrop_pass({
		get_offer = session_state.offer,
		room_translate = room_translate,
	})
end

function M.is_transforming()
	return trade_animate.is_transforming()
end

function M.draw_pass()
	trade_fly.draw_pass()
end

function M.open()
	lifecycle.open_standalone()
end

function M.open_then_dealer()
	lifecycle.open_then_dealer()
end

function M.on_pick(e)
	handlers.on_pick(e)
end

function M.on_skip_add()
	handlers.on_skip_add()
end

function M.on_skip_remove()
	handlers.on_skip_remove()
end

function M.teardown_run()
	session_state.teardown()
	trade_fly.clear()
	trade_animate.clear()
end

return M
