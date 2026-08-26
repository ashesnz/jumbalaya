--[[
	word_game/ui/token_reward.lua - Stage 1-1 timer-to-token reward fly animation.

	When the player clears hand 1-1, remaining timeline seconds (floored)
	become tokens. 	Coins fly from the timeline into the token pile.
]]

local Layout = require("word_game.ui.layout")
local state = require("word_game.model.state")

local M = {}

local STICKER_CELL = { x = 0, y = 0 }
local FLY_DUR = 0.52
local STAGGER = 0.042
local ARC = 42

local flyers = {}
local active = false
local on_done = nil
local total = 0
local spawned = 0
local landed = 0
local spawn_acc = 0
local end_x, end_y = 0, 0
local captured_time = nil
local grant_on_land = true
local fly_from_x, fly_from_y, fly_to_x, fly_to_y

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_in_out(t)
	t = clamp01(t)
	return t * t * (3 - 2 * t)
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

function M.is_eligible()
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.set == 1 and wr.hand_index == 1
end

function M.earned_amount()
	if captured_time ~= nil then
		return math.floor(captured_time)
	end
	local tt = WORD_GAME and WORD_GAME.TimelineTimer
	if not tt then return 0 end
	return math.floor(tt.time_remaining or 0)
end

function M.capture_timer()
	if not M.is_eligible() or captured_time ~= nil then return end
	local tt = WORD_GAME and WORD_GAME.TimelineTimer
	if not tt then return end
	captured_time = tt.time_remaining or 0
	tt.is_active = false
end

function M.is_active()
	return active
end

local function timeline_center_px()
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local rect = Layout.timeline_rect()
	local w = rect.w * ts
	local h = rect.h * ts
	local slant = (rect.slant or (rect.h * 0.88)) * ts
	local x = rect.x * ts
	local y = rect.y * ts
	return x + (w - slant * 0.5) * 0.5, y + h * 0.5
end

local function resolve_target_px()
	if G.deck and WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.token_center_px then
		local cx, cy = WORD_GAME.TableDeck.token_center_px(G.deck)
		if cx and cy then return cx, cy end
	end
	local deck = Layout.deck_rect()
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	return (deck.x + deck.w * 0.5) * ts, deck.y * ts
end

local function sticker_quad()
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.coin
	if not atlas or not atlas.image then return end
	local iw, ih = atlas.image:getDimensions()
	local px, py = atlas.px or iw, atlas.py or ih
	local qx = STICKER_CELL.x * px
	local qy = STICKER_CELL.y * py
	return atlas.image, love.graphics.newQuad(qx, qy, px, py, iw, ih), px, py
end

local function spawn_flyer()
	local sx = (fly_from_x or 0) + (math.random() - 0.5) * 18
	local sy = (fly_from_y or 0) + (math.random() - 0.5) * 10
	local tx = (fly_to_x or sx) + (math.random() - 0.5) * 14
	local ty = (fly_to_y or sy) + (math.random() - 0.5) * 10
	local dx, dy = tx - sx, ty - sy
	local len = math.sqrt(dx * dx + dy * dy)
	local nx, ny = 0, -1
	if len > 0.001 then
		nx, ny = -dy / len, dx / len
	end
	flyers[#flyers + 1] = {
		sx = sx,
		sy = sy,
		ex = tx,
		ey = ty,
		nx = nx,
		ny = ny,
		t = 0,
		dur = FLY_DUR + math.random() * 0.08,
		spin = (math.random() - 0.5) * 10,
		phase = math.random() * math.pi * 2,
	}
end

local function on_flyer_landed()
	if grant_on_land then
		state.add_tokens(1)
		if WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.bump_token_display then
			WORD_GAME.TableDeck.bump_token_display()
		end
		if play_sfx then
			play_sfx("coin2", 0.85 + math.random() * 0.2, 0.55 + math.random() * 0.15)
		end
	end
	landed = landed + 1
end

local function finish()
	active = false
	flyers = {}
	spawned = 0
	landed = 0
	total = 0
	spawn_acc = 0
	local cb = on_done
	on_done = nil
	if cb then cb() end
end

function M.try_award(callback)
	if active then return true end
	if not M.is_eligible() then return false end

	local amount = M.earned_amount()
	if amount <= 0 then
		captured_time = nil
		return false
	end

	local tt = WORD_GAME and WORD_GAME.TimelineTimer
	if tt and tt.freeze_reward_display then
		tt.freeze_reward_display(amount)
	elseif tt then
		tt.is_active = false
		tt.time_remaining = amount
	end

	total = amount
	spawned = 0
	landed = 0
	spawn_acc = 0
	flyers = {}
	on_done = callback
	active = true
	grant_on_land = true
	end_x, end_y = resolve_target_px()
	fly_from_x, fly_from_y = timeline_center_px()
	fly_to_x, fly_to_y = end_x, end_y

	if attention then
		attention("+" .. tostring(amount) .. " tokens", G.C.GOLD or { 1, 0.85, 0.35, 1 }, 1.4)
	end
	if play_sfx then
		play_sfx("coin1", 1, 0.75)
	end

	return true
end

function M.spend_fly(amount, callback)
	amount = math.floor(amount or 0)
	if amount <= 0 then
		if callback then callback() end
		return
	end

	-- Update the sidebar display even when another token animation is active.
	-- The marketplace can be interacted with while the reward animation is running.
	if WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.spend_tokens_display then
		WORD_GAME.TableDeck.spend_tokens_display(amount)
	end

	if active then
		if callback then callback() end
		return
	end

	total = math.min(amount, 12)
	spawned = 0
	landed = 0
	spawn_acc = 0
	flyers = {}
	on_done = callback
	active = true
	grant_on_land = false
	-- Tokens leave the pile and continue beyond the playfield.
	-- Keep the pile as the source so the animation agrees with the balance roll.
	fly_from_x, fly_from_y = resolve_target_px()
	local room = G and G.ROOM
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	fly_to_x = (room and room.T.w or G.TILE_W or 20) * ts + 80
	fly_to_y = fly_from_y - 24

	if attention then
		attention("-" .. tostring(amount) .. " tokens", G.C.RED or { 1, 0.35, 0.35, 1 }, 1.2)
	end
	if play_sfx then
		play_sfx("coin2", 0.9, 0.65)
	end
end

function M.update(dt)
	if not active then return end
	dt = dt or (G and G.real_dt) or 0.016

	spawn_acc = spawn_acc + dt
	while spawned < total and spawn_acc >= STAGGER do
		spawn_acc = spawn_acc - STAGGER
		spawned = spawned + 1
		spawn_flyer()
	end

	for i = #flyers, 1, -1 do
		local f = flyers[i]
		f.t = f.t + dt
		local u = ease_in_out(f.t / f.dur)
		local arc = math.sin(u * math.pi) * ARC
		f.x = f.sx + (f.ex - f.sx) * u + f.nx * arc
		f.y = f.sy + (f.ey - f.sy) * u + f.ny * arc
		f.rot = f.spin * u + math.sin(f.phase + u * 8) * 0.18
		f.scale = 0.42 + 0.58 * math.sin(u * math.pi)
		f.alpha = u < 0.92 and 1 or math.max(0, 1 - (u - 0.92) / 0.08)
		if f.t >= f.dur then
			on_flyer_landed()
			table.remove(flyers, i)
		end
	end

	if spawned >= total and landed >= total and #flyers == 0 then
		finish()
	end
end

function M.draw_pass()
	if not active and #flyers == 0 then return end
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	M.update(math.min(0.05, love.timer and love.timer.getDelta() or 0.016))

	local img, quad, pw, ph = sticker_quad()
	if not img or not quad then return end

	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local size = math.max(22, G.CARD_W * ts * 0.16)
	local scale = size / pw

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()
	love.graphics.setShader()
	room_translate()

	for _, f in ipairs(flyers) do
		local a = f.alpha or 1
		love.graphics.setColor(1, 1, 1, a)
		love.graphics.draw(img, quad, f.x, f.y, f.rot or 0, scale, scale, pw * 0.5, ph * 0.5)
		if a > 0.35 then
			love.graphics.setColor(1, 0.92, 0.45, a * 0.22)
			love.graphics.draw(img, quad, f.x, f.y, f.rot or 0, scale * 1.18, scale * 1.18, pw * 0.5, ph * 0.5)
		end
	end

	love.graphics.pop()
	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	love.graphics.setColor(cr, cg, cb, ca)
end

function M.reset()
	active = false
	flyers = {}
	on_done = nil
	total = 0
	spawned = 0
	landed = 0
	spawn_acc = 0
	captured_time = nil
	grant_on_land = true
end

return M
