--[[ word_game/ui/trade/card_fly.lua - Marketplace letter fly FX (LetterFaces composite) ]]

local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local Layout = require("word_game.ui.layout")
local preview = require("word_game.ui.trade.preview")
local stamp_layout = require("word_game.ui.perks.stamp.layout")
local LetterFaces = require("word_game.ui.cards.letter_faces")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")

local Busy = facade.busy()

local M = {}

local MARKET_CARD_SCALE = 0.5
local FLY_DURATION = 0.4
local MODIFY_DURATION = 0.45

local active = nil

local function smoothstep(u)
	return u * u * (3 - 2 * u)
end

local function tile_scale()
	local g = game()
	return (g.TILESIZE or 20) * (g.TILESCALE or 1)
end

local function market_card_size_tiles()
	local g = game()
	return (g.CARD_W or 1) * MARKET_CARD_SCALE, (g.CARD_H or 1.4) * MARKET_CARD_SCALE
end

local function deck_card_size_tiles()
	local g = game()
	return g.CARD_W or 1, g.CARD_H or 1.4
end

local function node_tiles_xywh(node)
	if not node then return nil end
	local x, y, w, h = stamp_layout.node_world_xywh(node)
	if not x and node.T then
		x, y, w, h = node.T.x, node.T.y, node.T.w, node.T.h
	end
	if not x then return nil end
	return x, y, w or 0, h or 0
end

local function market_card_node(menu, market_index)
	if not menu or not menu.find_node_by_id then return nil end
	return menu:find_node_by_id("trade_market_card_" .. market_index)
end

local function clear_market_slot(node)
	if not node or not node.config then return end
	node.config.object = nil
end

local function letter_color_key(item, deck_card)
	if deck_card then
		return LetterFaces.color_key_for_card(deck_card)
	end
	return item.color or LetterPalette.DEFAULT_FACE_COLOR
end

local function set_card_visible(card, visible)
	if not card or not card.states then return end
	card.states.visible = visible
end

local function lerp_rgba(a, b, t)
	return {
		a[1] + (b[1] - a[1]) * t,
		a[2] + (b[2] - a[2]) * t,
		a[3] + (b[3] - a[3]) * t,
		(a[4] or 1) + ((b[4] or 1) - (a[4] or 1)) * t,
	}
end

local function draw_composite_tiles(x, y, w, h, letter, fill_rgba, alpha)
	if not love or not love.graphics then return end
	local ts = tile_scale()
	local frame_atlas = LetterFaces.frame_atlas()
	local letters_atlas = LetterFaces.letters_atlas()
	if not frame_atlas or not letters_atlas then return end
	local cell_w, cell_h = frame_atlas.px or 71, frame_atlas.py or 95
	local px_w, px_h = w * ts, h * ts
	local cx = x * ts + px_w * 0.5
	local cy = y * ts + px_h * 0.5
	local pos = LetterFaces.glyph_pos(letter)
	local a = alpha or 1

	local function draw_layer(atlas, sprite_pos, tint)
		local iw, ih = atlas.image:getDimensions()
		local quad = love.graphics.newQuad(
			sprite_pos.x * cell_w, sprite_pos.y * cell_h,
			cell_w, cell_h, iw, ih)
		love.graphics.setColor(tint[1], tint[2], tint[3], a)
		love.graphics.draw(atlas.image, quad, cx, cy, 0, px_w / cell_w, px_h / cell_h, cell_w * 0.5, cell_h * 0.5)
	end

	draw_layer(frame_atlas, { x = 0, y = 0 }, fill_rgba)
	draw_layer(letters_atlas, pos, { 1, 1, 1, 1 })
end

function M.is_active()
	return active ~= nil
end

function M.reset()
	if active and active.hidden_card then
		set_card_visible(active.hidden_card, true)
	end
	active = nil
	Busy.set("trade_ui_busy", false)
end

local function finish()
	if not active then return end
	local state = active
	if state.hidden_card then
		set_card_visible(state.hidden_card, true)
	end
	active = nil
	Busy.set("trade_ui_busy", false)

	if state.menu and state.market_index then
		preview.refresh_market_slot(state.menu, state.market_index)
	end
	if state.on_complete then
		state.on_complete()
	end
end

local function begin_fly(state)
	active = state
	Busy.set("trade_ui_busy", true)
	if play_sfx then
		play_sfx("card_slide1", 0.9, 0.62)
	end
end

function M.start(opts)
	opts = opts or {}
	if active then return false end
	local kind = opts.kind or "add"
	local item = opts.item
	local market_index = opts.market_index
	if not item or not market_index or not item.letter then return false end

	local g = game()
	local menu = g and g.OVERLAY_MENU
	local slot_node = market_card_node(menu, market_index)
	local sx, sy, sw, sh = node_tiles_xywh(slot_node)
	if not sx then return false end

	local deck = Layout.deck_rect()
	local dw, dh = deck_card_size_tiles()
	local tx = deck.x + (deck.w - dw) * 0.5
	local ty = deck.y + (deck.h - dh) * 0.5

	local letter = item.letter
	local deck_card = item.card
	local color_from = letter_color_key(item, deck_card)
	local color_to = LetterPalette.MODIFIED_FACE_COLOR

	clear_market_slot(slot_node)
	if item.preview then
		item.preview = nil
		item.preview_is_standalone = nil
	end

	local hidden_card = nil
	if kind == "remove" or kind == "modify" then
		if item.letter then
			deck_card = facade.deck().find_deck_card(item.letter)
			item.card = deck_card
		end
		hidden_card = deck_card
		set_card_visible(hidden_card, false)
	end

	if kind == "remove" then
		begin_fly({
			kind = kind,
			letter = letter,
			color_key = color_from,
			item = item,
			market_index = market_index,
			menu = menu,
			t = 0,
			dur = FLY_DURATION,
			sx = tx, sy = ty, sw = dw, sh = dh,
			tx = sx, ty = sy, tw = sw, th = sh,
			hidden_card = hidden_card,
			on_complete = opts.on_complete,
		})
		return true
	end

	if kind == "modify" then
		local from_fill = LetterFaces.fill_color(color_from)
		local to_fill = LetterFaces.fill_color(color_to)
		begin_fly({
			kind = kind,
			letter = letter,
			color_from = from_fill,
			color_to = to_fill,
			item = item,
			market_index = market_index,
			menu = menu,
			t = 0,
			dur = MODIFY_DURATION,
			sx = sx, sy = sy, sw = sw, sh = sh,
			hidden_card = hidden_card,
			on_complete = opts.on_complete,
		})
		return true
	end

	-- add: marketplace slot → deck (draft happens after landing)
	begin_fly({
		kind = "add",
		letter = letter,
		color_key = color_from,
		item = item,
		market_index = market_index,
		menu = menu,
		t = 0,
		dur = FLY_DURATION,
		sx = sx, sy = sy, sw = sw, sh = sh,
		tx = tx, ty = ty, tw = dw, th = dh,
		on_complete = opts.on_complete,
	})
	return true
end

function M.start_add_fly(opts)
	opts.kind = "add"
	return M.start(opts)
end

function M.update(dt)
	if not active then return end
	dt = dt or 0
	active.t = active.t + dt
	local u = active.dur > 0 and math.min(1, active.t / active.dur) or 1
	local e = smoothstep(u)
	active.ease = e
	if u >= 1 then
		finish()
	end
end

function M.draw()
	if not active or not love or not love.graphics then return end
	local g = game()
	if not g or not g.ROOM then return end
	local e = active.ease or 0
	local letter = active.letter
	if not letter then return end

	love.graphics.push()
	stamp_layout.room_translate()

	if active.kind == "modify" then
		local fill = lerp_rgba(active.color_from, active.color_to, e)
		draw_composite_tiles(active.sx, active.sy, active.sw, active.sh, letter, fill, 1)
	else
		local x = active.sx + (active.tx - active.sx) * e
		local y = active.sy + (active.ty - active.sy) * e
		local w = active.sw + (active.tw - active.sw) * e
		local h = active.sh + (active.th - active.sh) * e
		local fill = LetterFaces.fill_color(active.color_key)
		draw_composite_tiles(x, y, w, h, letter, fill, 1)
	end

	love.graphics.pop()
end

return M
