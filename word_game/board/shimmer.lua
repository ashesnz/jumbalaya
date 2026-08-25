--[[ word_game.board/shimmer.lua - Lock-in outline around placed cards. ]]

local config = require "word_game.board.config"
local layout = require "word_game.board.layout"

local M = {}

function M.start_card(session, card)
	if not card then return end
	session.card_shimmer_t = session.card_shimmer_t or {}
	session.card_shimmer_t[card] = config.LOCK_SHIMMER_DURATION
end

function M.update(session, dt)
	if not session.card_shimmer_t then return end
	for card, t in pairs(session.card_shimmer_t) do
		if card.REMOVED then
			session.card_shimmer_t[card] = nil
		elseif t and t > 0 then
			session.card_shimmer_t[card] = math.max(0, t - dt)
		end
	end
end

--- Outside-only border shimmer; rect is the placed card bounds in canvas pixels.
local function draw_outline_shimmer(px, py, pw, ph, progress)
	local envelope = math.sin(progress * math.pi)
	local pad = config.OUTLINE_PAD
	local radius = config.CORNER_RADIUS + 2
	local now = (G.TIMERS and G.TIMERS.REAL) or 0

	love.graphics.setShader()

	for ring = 1, 2 do
		local ring_progress = (progress + ring * 0.3) % 1
		local expand = pad + ring_progress * 12
		local alpha = envelope * (1 - ring_progress) * 0.9
		love.graphics.setColor(1, 0.94, 0.62, alpha)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle(
			'line',
			px - expand, py - expand,
			pw + expand * 2, ph + expand * 2,
			radius + expand * 0.3, radius + expand * 0.3
		)
	end

	local border_pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 6 + now * 10)
	love.graphics.setColor(1, 0.98, 0.72, envelope * (0.4 + 0.5 * border_pulse))
	love.graphics.setLineWidth(2.5)
	love.graphics.rectangle(
		'line',
		px - pad, py - pad,
		pw + pad * 2, ph + pad * 2,
		radius, radius
	)

	love.graphics.setColor(1, 0.88, 0.42, envelope * 0.4)
	love.graphics.setLineWidth(1.5)
	love.graphics.rectangle(
		'line',
		px - pad - 2, py - pad - 2,
		pw + (pad + 2) * 2, ph + (pad + 2) * 2,
		radius + 1, radius + 1
	)
end

--- Draw active lock outlines in room/canvas pixel space.
function M.draw(session)
	if not session.area or not session.card_shimmer_t then return end

	local duration = config.LOCK_SHIMMER_DURATION
	for card, remaining in pairs(session.card_shimmer_t) do
		if remaining and remaining > 0 and card.area == session.area then
			local px, py, pw, ph = layout.card_pixels(card)
			local progress = 1 - (remaining / duration)
			draw_outline_shimmer(px, py, pw, ph, progress)
		end
	end

	love.graphics.setShader()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
end

return M
