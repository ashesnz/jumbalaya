--[[ word_game/ui/trade/card_fly.lua - Fly marketplace preview card into the sidebar deck ]]

local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local Layout = require("word_game.ui.layout")
local preview = require("word_game.ui.trade.preview")
local stamp_layout = require("word_game.ui.perks.stamp.layout")

local MARKET_CARD_SCALE = 0.5

local Busy = facade.busy()

local M = {}

local FLY_DURATION = 0.42
local active = nil

local function smoothstep(u)
	return u * u * (3 - 2 * u)
end

local function sync_card_transform(card)
	if not card or not card.T then return end
	if card.hard_set_T then
		card:hard_set_T(card.T.x, card.T.y, card.T.w, card.T.h)
	end
	if card.snap_VT then
		card:snap_VT()
	end
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

local function hide_market_slot(node)
	if not node or not node.config then return end
	if node.config.object and node.config.object.states then
		node.config.object.states.visible = false
	end
end

function M.is_active()
	return active ~= nil
end

function M.reset()
	if active and active.card then
		if active.card.remove then
			active.card:remove()
		else
			active.card.REMOVED = true
		end
	end
	active = nil
	Busy.set("trade_ui_busy", false)
end

local function finish()
	if not active then return end
	local item = active.item
	local index = active.market_index
	local menu = active.menu
	local on_complete = active.on_complete
	local card = active.card

	if card then
		if card.remove then
			card:remove()
		else
			card.REMOVED = true
		end
	end
	if item then
		item.preview = nil
		item.preview_is_standalone = nil
	end

	active = nil
	Busy.set("trade_ui_busy", false)

	if menu and index then
		preview.refresh_market_slot(menu, index)
	end
	if on_complete then
		on_complete()
	end
end

function M.start_add_fly(opts)
	opts = opts or {}
	if active then return false end
	local item = opts.item
	local market_index = opts.market_index
	if not item or not market_index then return false end

	local g = game()
	local menu = g and g.OVERLAY_MENU
	local slot_node = market_card_node(menu, market_index)
	local sx, sy, sw, sh = node_tiles_xywh(slot_node)
	if not sx then
		return false
	end

	local card = item.preview
	if not card or card.REMOVED then
		local g = game()
		local mw = (g.CARD_W or 1) * MARKET_CARD_SCALE
		local mh = (g.CARD_H or 1.4) * MARKET_CARD_SCALE
		card = preview.ensure(item, mw, mh)
	end
	if not card or not card.T then
		return false
	end

	local tw = g.CARD_W or 1
	local th = g.CARD_H or 1.4
	local deck = Layout.deck_rect()
	local tx = deck.x + (deck.w - tw) * 0.5
	local ty = deck.y + (deck.h - th) * 0.5

	hide_market_slot(slot_node)
	if card.set_scene_parent then
		card:set_scene_parent(nil)
	end
	if card.set_container and g.ROOM then
		card:set_container(g.ROOM)
	end
	if card.states then
		card.states.visible = true
		if card.states.drag then card.states.drag.can = false end
		if card.states.hover then card.states.hover.can = false end
		if card.states.click then card.states.click.can = false end
		if card.states.collide then card.states.collide.can = false end
	end

	card.T.x = sx
	card.T.y = sy
	card.T.w = sw
	card.T.h = sh
	sync_card_transform(card)

	active = {
		card = card,
		item = item,
		market_index = market_index,
		menu = menu,
		t = 0,
		dur = FLY_DURATION,
		sx = sx,
		sy = sy,
		sw = sw,
		sh = sh,
		tx = tx,
		ty = ty,
		tw = tw,
		th = th,
		on_complete = opts.on_complete,
	}
	Busy.set("trade_ui_busy", true)
	if play_sfx then
		play_sfx("card_slide1", 0.92, 0.65)
	end
	return true
end

function M.update(dt)
	if not active then return end
	dt = dt or 0
	active.t = active.t + dt
	local u = active.dur > 0 and math.min(1, active.t / active.dur) or 1
	local e = smoothstep(u)
	local card = active.card
	card.T.x = active.sx + (active.tx - active.sx) * e
	card.T.y = active.sy + (active.ty - active.sy) * e
	card.T.w = active.sw + (active.tw - active.sw) * e
	card.T.h = active.sh + (active.th - active.sh) * e
	sync_card_transform(card)
	if u >= 1 then
		finish()
	end
end

function M.draw()
	if not active or not active.card or not active.card.draw then return end
	local g = game()
	if not g or not g.ROOM then return end
	love.graphics.push()
	g.ROOM:translate_container()
	active.card:draw()
	love.graphics.pop()
end

return M
