--[[ word_game/ui/trade/fly.lua - marketplace card fly-to-deck animation ]]

local Layout = require("word_game.ui.layout")

local M = {}

local flyer
local flyer_callback
local FLY_TIME = 0.65

function M.is_flying()
	return flyer ~= nil
end

function M.clear()
	flyer = nil
	flyer_callback = nil
end

local function deck_target_px()
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	if G.deck and G.deck.T then
		local t = G.deck.T
		return (t.x + (t.w or 0) * 0.5) * ts, (t.y + (t.h or 0) * 0.5) * ts
	end
	local rect = Layout.deck_rect()
	return (rect.x + rect.w * 0.5) * ts, (rect.y + rect.h * 0.5) * ts
end

local function room_translate()
	local room = G and G.ROOM
	if not room or not love or not love.graphics then return end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

local function draw_flyer_card(item, x, y, rot, alpha)
	if not item then return end
	local size = math.max(30, (G.CARD_W or 1) * (G.TILESCALE or 1) * (G.TILESIZE or 1))
	local LetterFaces = require "word_game.ui.letter_card_faces"
	LetterFaces.draw_composite(x, y, rot, size, size * ((G.CARD_H or 1) / (G.CARD_W or 1)),
		item.letter, item.color, alpha)
end

function M.start_card_fly(item, callback, start_x, start_y)
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local sx, sy = start_x, start_y
	if not sx or not sy then
		local card = item and item.market_card
		local transform = card and card.T
		sx = transform and (transform.x + (transform.w or G.CARD_W) * 0.5) * ts
		sy = transform and (transform.y + (transform.h or G.CARD_H) * 0.5) * ts
	end
	if not sx or not sy then
		local room = G.ROOM and G.ROOM.T
		sx = ((room and room.w or G.TILE_W or 20) * 0.5) * ts
		sy = ((room and room.h or G.TILE_H or 11) * 0.45) * ts
	end
	local ex, ey = deck_target_px()
	flyer = {
		item = item,
		t = 0,
		sx = sx,
		sy = sy,
		ex = ex,
		ey = ey,
		rot = 0,
		landed = false,
	}
	flyer_callback = callback
end

local function fly_delta(dt)
	dt = dt or (G and G.real_dt) or 0.016
	if (not dt or dt <= 0) and love and love.timer and love.timer.getDelta then
		dt = love.timer.getDelta()
	end
	if not dt or dt <= 0 then dt = 0.016 end
	return math.min(0.05, dt)
end

function M.step_card_fly(dt)
	if not flyer then return false end
	flyer.t = flyer.t + fly_delta(dt)
	local u = math.min(1, flyer.t / FLY_TIME)
	if u >= 1 and not flyer.landed then
		local done = flyer_callback
		flyer.landed = true
		flyer_callback = nil
		flyer = nil
		if done then done() end
		return true
	end
	return false
end

function M.draw_pass()
	if not flyer or not G.ROOM or not love.graphics then return end
	local u = math.min(1, flyer.t / FLY_TIME)
	local eased = 1 - (1 - u) * (1 - u)
	local arc = math.sin(u * math.pi) * 0.8 * (G.TILESIZE or 1) * (G.TILESCALE or 1)
	local x = flyer.landed and flyer.ex or flyer.sx + (flyer.ex - flyer.sx) * eased
	local y = flyer.landed and flyer.ey or flyer.sy + (flyer.ey - flyer.sy) * eased - arc
	flyer.rot = flyer.landed and flyer.rot or (math.pi * 0.08) * math.sin(u * math.pi)

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()
	love.graphics.push()
	love.graphics.setShader()
	room_translate()
	draw_flyer_card(flyer.item, x, y, flyer.rot, 1)
	love.graphics.pop()
	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	love.graphics.setColor(cr, cg, cb, ca)
end

return M
