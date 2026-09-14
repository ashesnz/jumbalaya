--[[
	word_game/ui/table/token_reward/init.lua - Stage-end reward fly animation.

	Time Run (1-1): leftover timeline seconds become tokens.
	Classic: banked stage score becomes tokens (1 point = 1 token).
]]

local capture = require("word_game.ui.table.token_reward.capture")
local session = require("word_game.ui.table.token_reward.session")
local flyers = require("word_game.ui.table.token_reward.flyers")
local draw = require("word_game.ui.table.token_reward.draw")

local M = {}

function M.is_eligible()
	return capture.is_eligible()
end

function M.earned_amount()
	return capture.earned_amount()
end

function M.capture_timer()
	M.capture_reward()
end

function M.capture_reward()
	capture.capture_reward()
end

function M.is_active()
	return session.is_active()
end

function M.try_award(callback)
	return flyers.try_award(callback)
end

function M.spend_fly(amount, callback)
	flyers.spend_fly(amount, callback)
end

function M.update(dt)
	flyers.update(dt)
end

function M.draw_pass()
	draw.draw_pass()
end

function M.reset()
	session.reset()
end

return M
