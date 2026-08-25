--[[ word_game.board/draw.lua - Full-width placement row background. ]]

local config = require "word_game.board.config"
local layout = require "word_game.board.layout"

local M = {}

-- Constant backdrop opacity; independent of how many cards are placed so
-- dragging cards in/out never shifts the row's transparency.
local BACKDROP_FILL_ALPHA = 0.18
local BACKDROP_LINE_ALPHA = 0.28

--- @param session PlacementTable
function M.shadows(session)
	local area = session.area
	if not area or not area.cards then return end
	local j = WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state and WORD_GAME.Jumble.state()
	if j and j.boss_puzzle_hidden then return end

	local px, py, pw, ph = layout.row_pixels(session)

	love.graphics.setColor(0, 0, 0, BACKDROP_FILL_ALPHA)
	love.graphics.rectangle('fill', px, py, pw, ph, config.CORNER_RADIUS, config.CORNER_RADIUS)
	love.graphics.setColor(1, 1, 1, BACKDROP_LINE_ALPHA)
	love.graphics.setLineWidth(1.5)
	love.graphics.rectangle('line', px, py, pw, ph, config.CORNER_RADIUS, config.CORNER_RADIUS)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
end

return M
