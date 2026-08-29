--[[ word_game/ui/perk_market.lua - Perk marketplace overlay ]]

local widgets = require("word_game.ui.widgets")
local perk = require("word_game.model.perk")
local state = require("word_game.model.state")
local Layout = require("word_game.ui.layout")

local M = {}

local offer
local flyer
local flyer_callback
local FLY_TIME = 0.7

local function notice(msg, colour)
	if spawn_attention then
		spawn_attention({
			scale = 0.7,
			text = msg,
			hold = 1.4,
			align = "cm",
			major = G.ROOM_ATTACH,
			colour = colour or G.C.RED,
		})
	elseif attention then
		attention(msg, colour or G.C.RED, 1.2)
	end
end

local function perk_sprite(perk, w, h)
	w = w or G.CARD_W * 0.9
	h = h or G.CARD_H * 0.9
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES["Perk"]
	if not atlas or not perk or not perk.pos then
		return nil
	end
	local sprite = Sprite(0, 0, w, h, atlas, perk.pos)
	sprite.states.drag.can = false
	sprite.states.hover.can = false
	sprite.states.collide.can = false
	sprite.states.click.can = false
	return sprite
end

local function perk_column(entry)
	local w, h = G.CARD_W * 0.9, G.CARD_H * 0.9
	local cost = math.floor(entry.token_cost or 0)
	local affordable = perk.can_afford(entry)
	local sprite = perk_sprite(entry, w, h)
	if sprite then
		entry.market_sprite = sprite
	end
	local sprite_node = sprite
		and { n = G.UI.OBJECT, config = { object = sprite, w = w, h = h } }
		or { n = G.UI.TEXT, config = { text = "?", scale = 0.8, colour = G.C.WHITE, shadow = true } }

	return { n = G.UI.COLUMN, config = { align = "cm", padding = 0.08 }, nodes = {
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = { sprite_node } },
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.02, maxw = 2.8 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = cost .. " tokens",
				scale = 0.34,
				colour = affordable and G.C.GOLD or G.C.RED,
				shadow = true,
			}},
		}},
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.02, maxw = 2.8 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = entry.name or "Perk",
				scale = 0.3,
				colour = G.C.GOLD,
				shadow = true,
			}},
		}},
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.02, maxw = 2.8, minh = 0.55 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = entry.desc or "",
				scale = 0.22,
				colour = G.C.UI.TEXT_LIGHT,
				shadow = true,
			}},
		}},
		{ n = G.UI.ROW, config = {
			align = "cm",
			minw = w + 0.15,
			minh = 0.55,
			r = 0.1,
			padding = 0.06,
			hover = affordable,
			colour = affordable and G.C.GREEN or G.C.UI.BACKGROUND_INACTIVE,
			button = affordable and "alpha_voucher_pick" or nil,
			ref_table = entry,
			shadow = true,
		}, nodes = {
			{ n = G.UI.TEXT, config = {
				text = affordable and "Choose" or "Need tokens",
				scale = 0.32,
				colour = G.C.UI.TEXT_LIGHT,
				shadow = true,
			}},
		}},
	}}
end

local function perk_row(entries)
	local columns = {}
	for _, entry in ipairs(entries or {}) do
		columns[#columns + 1] = perk_column(entry)
		columns[#columns + 1] = { n = G.UI.COLUMN, config = { minw = 0.35 }, nodes = {} }
	end
	if #columns > 0 then
		columns[#columns] = nil
	end
	return { n = G.UI.ROW, config = {
		align = "cm",
		padding = 0.08,
		minh = 1.55 * G.CARD_H,
	}, nodes = columns }
end

function M.definition()
	if not offer then
		offer = perk.roll_offer(3)
	end

	local balance = state.tokens()
	local nodes = {
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.08 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = "PERK MARKETPLACE",
				scale = 0.5,
				colour = G.C.GOLD,
				shadow = true,
			}},
		}},
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.03 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = "Choose one perk for this showdown",
				scale = 0.28,
				colour = G.C.FILTER,
				shadow = true,
			}},
		}},
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = balance .. " tokens available",
				scale = 0.32,
				colour = G.C.GOLD,
				shadow = true,
			}},
		}},
		perk_row(offer),
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.08, minw = 3.0, minh = 0.6,
			r = 0.1, hover = true, colour = G.C.UI.BACKGROUND_INACTIVE,
			button = "alpha_voucher_skip", shadow = true }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = "Skip",
				scale = 0.32,
				colour = G.C.UI.TEXT_LIGHT,
				shadow = true,
			}},
		}},
	}

	return build_generic_options({ contents = nodes, no_back = true })
end

local function close_menu()
	offer = nil
	if G.FUNCS.close_overlay then
		G.FUNCS.close_overlay()
	end
end

local function after_selection()
	close_menu()
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.reset then
		WORD_GAME.TimelineTimer.reset(60.0)
	end
	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar:refresh()
	end
end

local function start_fly(entry, callback)
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local felt = Layout.felt_rect()
	local target_x = (felt.x - 0.8) * ts
	local target_y = (felt.y + felt.h * 0.5) * ts
	local sprite = entry and entry.market_sprite
	local transform = sprite and sprite.T
	local start_x = transform and (transform.x + (transform.w or 0) * 0.5) * ts
	local start_y = transform and (transform.y + (transform.h or 0) * 0.5) * ts
	if not start_x or not start_y then
		local room = G.ROOM and G.ROOM.T
		start_x = ((room and room.w or G.TILE_W or 20) * 0.5) * ts
		start_y = ((room and room.h or G.TILE_H or 11) * 0.5) * ts
	end
	flyer = { entry = entry, t = 0, sx = start_x, sy = start_y,
		ex = target_x, ey = target_y, rot = 0, landed = false }
	flyer_callback = callback
end

function M.draw_pass()
	if not flyer or not G.ROOM or not love.graphics then return end
	local dt = math.min(0.05, love.timer and love.timer.getDelta() or 0.016)
	flyer.t = flyer.t + dt
	local u = math.min(1, flyer.t / FLY_TIME)
	local eased = 1 - (1 - u) * (1 - u)
	local x = flyer.landed and flyer.ex or flyer.sx + (flyer.ex - flyer.sx) * eased
	local y = flyer.landed and flyer.ey or flyer.sy + (flyer.ey - flyer.sy) * eased - math.sin(u * math.pi) * 0.8 * (G.TILESIZE or 1) * (G.TILESCALE or 1)
	flyer.rot = flyer.landed and flyer.rot or -math.pi * 14 * u
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.Perk
	local image = atlas and atlas.image
	if image then
		local pw, ph = atlas.px or 71, atlas.py or 95
		local quad = love.graphics.newQuad(flyer.entry.pos.x * pw, flyer.entry.pos.y * ph, pw, ph,
			image:getDimensions())
		local size = math.max(30, (G.CARD_W or 1) * (G.TILESCALE or 1) * (G.TILESIZE or 1) * 0.9)
		love.graphics.push()
		local room = G.ROOM.T
		local ts_room = (G.TILESCALE or 1) * (G.TILESIZE or 1)
		love.graphics.translate(room.w * ts_room * 0.5, room.h * ts_room * 0.5)
		love.graphics.rotate(room.r or 0)
		love.graphics.translate(-room.w * ts_room * 0.5 + (room.x or 0) * ts_room,
			-room.h * ts_room * 0.5 + (room.y or 0) * ts_room)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(image, quad, x, y, flyer.rot, size / pw, size / ph, pw * 0.5, ph * 0.5)
		love.graphics.pop()
	end
	if u >= 1 and not flyer.landed then
		local done = flyer_callback
		flyer.landed, flyer_callback = true, nil
		if done then done() end
	end
end

local function open_overlay()
	G.SETTINGS.paused = true
	widgets.open(M.definition(), true)
end

function M.show()
	offer = perk.roll_offer(3)
	open_overlay()
end

function M.open()
	M.show()
end

local function finish_purchase(entry)
	perk.apply_showdown_bonus(entry)
	play_sfx("card_slide1", 0.9, 0.8)
end

G.FUNCS.alpha_voucher_skip = function()
	after_selection()
end

G.FUNCS.alpha_voucher_pick = function(e)
	local entry = e and e.config and e.config.ref_table
	if not entry then return end
	if not perk.can_afford(entry) then
		notice("Not enough tokens")
		play_sfx("cancel", 0.8, 0.6)
		return
	end

	local ok, err = perk.purchase(entry)
	if not ok then
		notice(err or "Can't buy perk")
		play_sfx("cancel", 0.8, 0.6)
		return
	end

	if WORD_GAME and WORD_GAME.PerkStamp and WORD_GAME.PerkStamp.queue then
		WORD_GAME.PerkStamp.queue(entry)
	end

	local cost = math.floor(entry.token_cost or 0)
	if WORD_GAME and WORD_GAME.TokenReward and WORD_GAME.TokenReward.spend_fly then
		WORD_GAME.TokenReward.spend_fly(cost)
	elseif WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.spend_tokens_display then
		WORD_GAME.TableDeck.spend_tokens_display(cost)
	end
	start_fly(entry, function() finish_purchase(entry) end)
end

return M
