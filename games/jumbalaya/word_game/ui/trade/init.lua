--[[ word_game/ui/trade/init.lua - Card Marketplace overlay facade ]]

local trade_definition = require("word_game.ui.trade.definition")
local session_state = require("word_game.ui.trade.session_state")
local lifecycle = require("word_game.ui.trade.lifecycle")
local modal_draw = require("word_game.ui.trade.modal_draw")
local refresh = require("word_game.ui.trade.refresh")
local card_fly = require("word_game.ui.trade.card_fly")

local M = {}

lifecycle.bind(M)

function M.definition()
	return trade_definition.build_overlay_definition()
end

function M.is_open()
	return session_state.is_open()
end

function M.draw_modal_on_top()
	modal_draw.draw_overlay_on_top()
end

function M.close()
	lifecycle.close()
end

function M.open()
	lifecycle.open_standalone()
end

function M.open_then_dealer()
	lifecycle.open_then_dealer()
end

function M.teardown_run()
	session_state.teardown()
end

function M.refresh_after_tokens_changed()
	refresh.after_tokens_changed()
end

function M.step_card_fly(dt)
	card_fly.update(dt)
end

function M.is_flying()
	return card_fly.is_active()
end

function M.is_transforming()
	return card_fly.is_active()
end

function M.draw_pass()
	card_fly.draw()
end
function M.on_pick(_e) end
function M.on_skip_add(_e) M.close() end
function M.on_skip_remove(_e) M.close() end

return M
