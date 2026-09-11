--[[ word_game/ui/dealt_hand.lua - Dealt hand geometry and card placement ]]

local M = {}

local felt_layout = require("word_game.ui.layout.felt")
local facade = require("word_game.ui.facade")
local game_access = require("word_game.model.game_access")

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
	if not G.dealt_letters then return end
	local wr = game_access.word_round()
	local locked = wr and wr.jumble and wr.jumble.locked_hand_layout
	if locked then
		G.dealt_letters.T.x = locked.x
		G.dealt_letters.T.y = locked.y
		G.dealt_letters.T.w = locked.w
		G.dealt_letters.T.h = locked.h
		if G.dealt_letters.hard_set_T then G.dealt_letters:hard_set_T(locked.x, locked.y, locked.w, locked.h) end
		if G.dealt_letters.cards and G.dealt_letters.cards[1] then
			if G.dealt_letters.relayout then G.dealt_letters:relayout() end
			if G.dealt_letters.hard_set_cards then G.dealt_letters:hard_set_cards() end
		end
		snap_moveable(G.dealt_letters)
		return
	end
	local hand_size = facade.hand_size().get()
	local hand_w = get_hand_area_width(hand_size)
	local hand_h = (G.CARD_H or G.dealt_letters.T.h) * 0.95
	local felt = felt_layout.hand_felt_rect()

	G.dealt_letters.T = G.dealt_letters.T or { x = 0, y = 0, w = hand_w, h = hand_h }
	G.dealt_letters.T.w = hand_w
	G.dealt_letters.T.h = hand_h
	G.dealt_letters.T.x = felt.x + math.max(0, (felt.w - hand_w) / 2)
	G.dealt_letters.T.y = G.TILE_H - hand_h - HAND_BOTTOM_MARGIN
	if G.dealt_letters.hard_set_T then G.dealt_letters:hard_set_T(G.dealt_letters.T.x, G.dealt_letters.T.y, hand_w, hand_h) end

	if G.dealt_letters.cards and G.dealt_letters.cards[1] then
		if G.dealt_letters.relayout then G.dealt_letters:relayout() end
		if G.dealt_letters.hard_set_cards then G.dealt_letters:hard_set_cards() end
	end

	snap_moveable(G.dealt_letters)
end

function M.stabilize()
	if not G.dealt_letters then return end
	M.apply_screen_position()
	if G.dealt_letters.cards and G.dealt_letters.cards[1] and G.dealt_letters.hard_set_cards then G.dealt_letters:hard_set_cards() end
end

return M