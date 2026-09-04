--[[ word_game/model/feedback.lua - Model-layer attention text requests (UI drains) ]]

local M = {}

local function queue()
	G.ARGS = G.ARGS or {}
	G.ARGS.word_feedback_queue = G.ARGS.word_feedback_queue or {}
	return G.ARGS.word_feedback_queue
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
	return G.ARGS and G.ARGS.word_feedback_queue
end

function M.clear()
	if G.ARGS then
		G.ARGS.word_feedback_queue = nil
	end
end

return M
