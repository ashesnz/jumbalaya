--[[ word_game/ui/dealt_hand.lua - Dealt hand geometry and card placement ]]

local M = {}

local felt_layout = require("word_game.ui.layout.felt")
local hand_size_cfg = require("word_game.config.hand_size")

local HAND_BOTTOM_MARGIN = 0.25

local function snap_moveable(moveable)
	if not moveable then return end
	if moveable.snap_VT then moveable:snap_VT() end
	if moveable.velocity then
		moveable.velocity.x = 0
		moveable.velocity.y = 0
		moveable.velocity.r = 0
		moveable.velocity.scale = 0
	end
end

function M.apply_screen_position()
	if not G.hand then return end
	local wr = G.GAME and G.GAME.word_round
	local locked = wr and wr.jumble and wr.jumble.locked_hand_layout
	if locked then
		G.hand.T.x = locked.x
		G.hand.T.y = locked.y
		G.hand.T.w = locked.w
		G.hand.T.h = locked.h
		if G.hand.hard_set_T then G.hand:hard_set_T(locked.x, locked.y, locked.w, locked.h) end
		if G.hand.cards and G.hand.cards[1] then
			if G.hand.relayout then G.hand:relayout() end
			if G.hand.hard_set_cards then G.hand:hard_set_cards() end
		end
		snap_moveable(G.hand)
		return
	end
	local hand_size = hand_size_cfg.get()
	local hand_w = get_hand_area_width(hand_size)
	local hand_h = (G.CARD_H or G.hand.T.h) * 0.95
	local felt = felt_layout.hand_felt_rect()

	G.hand.T = G.hand.T or { x = 0, y = 0, w = hand_w, h = hand_h }
	G.hand.T.w = hand_w
	G.hand.T.h = hand_h
	G.hand.T.x = felt.x + math.max(0, (felt.w - hand_w) / 2)
	G.hand.T.y = G.TILE_H - hand_h - HAND_BOTTOM_MARGIN
	if G.hand.hard_set_T then G.hand:hard_set_T(G.hand.T.x, G.hand.T.y, hand_w, hand_h) end

	if G.hand.cards and G.hand.cards[1] then
		if G.hand.relayout then G.hand:relayout() end
		if G.hand.hard_set_cards then G.hand:hard_set_cards() end
	end

	snap_moveable(G.hand)
end

function M.stabilize()
	if not G.hand then return end
	M.apply_screen_position()
	if G.hand.cards and G.hand.cards[1] and G.hand.hard_set_cards then G.hand:hard_set_cards() end
end

return M