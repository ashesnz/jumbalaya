--[[ word_game/ui/trade/session_state.lua - Marketplace open flags and active offer ]]

local preview = require("word_game.ui.trade.preview")
local card_fly = require("word_game.ui.trade.card_fly")

local M = {}

local open = false
local standalone = false
local offer = nil

function M.is_open()
	return open
end

function M.is_standalone()
	return standalone
end

function M.offer()
	return offer
end

function M.set_offer(next_offer)
	offer = next_offer
end

function M.mark_open(standalone_mode)
	open = true
	standalone = standalone_mode == true
end

function M.teardown()
	card_fly.reset()
	preview.teardown_offer(offer)
	offer = nil
	open = false
	standalone = false
end

return M
