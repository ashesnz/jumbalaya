--[[
	word_game/model/feedback/init.lua - Model-side word feedback queue on live_game().ARGS for UI to drain

	Core: none
	Store: none
	Presentation: none
]]

local live_game = require("word_game.model.live_game")

local M = {}

local function queue()
	live_game().ARGS = live_game().ARGS or {}
	live_game().ARGS.word_feedback_queue = live_game().ARGS.word_feedback_queue or {}
	return live_game().ARGS.word_feedback_queue
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
	return live_game().ARGS and live_game().ARGS.word_feedback_queue
end

function M.clear()
	if live_game().ARGS then
		live_game().ARGS.word_feedback_queue = nil
	end
end

return M
