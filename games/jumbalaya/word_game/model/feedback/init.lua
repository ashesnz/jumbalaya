--[[
	word_game/model/feedback/init.lua - Model-side word feedback queue on the game shell for UI to drain

	Core: none
	Store: none
	Presentation: none
]]

local live_game = require("word_game.model.live_game")

local M = {}

local function queue()
	local g = live_game()
	g.word_feedback_queue = g.word_feedback_queue or {}
	return g.word_feedback_queue
end

function M.show(text, colour, hold, offset_y)
	table.insert(queue(), {
		text = text,
		colour = colour,
		hold = hold,
		offset_y = offset_y,
	})
end

function M.pending()
	local g = live_game()
	return g and g.word_feedback_queue
end

function M.clear()
	local g = live_game()
	if g then
		g.word_feedback_queue = nil
	end
end

return M
