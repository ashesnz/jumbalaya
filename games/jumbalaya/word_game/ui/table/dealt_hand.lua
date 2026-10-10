--[[ word_game/ui/dealt_hand.lua - Dealt hand geometry and card placement ]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

local felt_layout = require("word_game.ui.layout.felt")
local facade = require("word_game.ui.facade")
local game_access = facade.game_access()

local HAND_BOTTOM_MARGIN = 0.25

local function snap_spatial(node)
	if not node then return end
	if node.snap_drawn then node:snap_drawn() end
	if node.velocity then
		node.velocity.x = 0
		node.velocity.y = 0
		node.velocity.r = 0
		node.velocity.scale = 0
	end
end

function M.apply_screen_position()
	if not game().dealt_letters then return end
	local wr = game_access.word_round()
	local locked = wr and wr.jumble and wr.jumble.locked_hand_layout
	if locked then
		game().dealt_letters.T.x = locked.x
		game().dealt_letters.T.y = locked.y
		game().dealt_letters.T.w = locked.w
		game().dealt_letters.T.h = locked.h
		if game().dealt_letters.snap_rect then game().dealt_letters:snap_rect(locked.x, locked.y, locked.w, locked.h) end
		if game().dealt_letters.cards and game().dealt_letters.cards[1] then
			if game().dealt_letters.relayout then game().dealt_letters:relayout() end
			if game().dealt_letters.hard_set_cards then game().dealt_letters:hard_set_cards() end
		end
		snap_spatial(game().dealt_letters)
		return
	end
	local hand_size = facade.hand_size().get()
	local hand_w = get_hand_area_width(hand_size)
	local hand_h = (game().CARD_H or game().dealt_letters.T.h) * 0.95
	local felt = felt_layout.hand_felt_rect()

	game().dealt_letters.T = game().dealt_letters.T or { x = 0, y = 0, w = hand_w, h = hand_h }
	game().dealt_letters.T.w = hand_w
	game().dealt_letters.T.h = hand_h
	game().dealt_letters.T.x = felt.x + math.max(0, (felt.w - hand_w) / 2)
	game().dealt_letters.T.y = game().TILE_H - hand_h - HAND_BOTTOM_MARGIN
	if game().dealt_letters.snap_rect then game().dealt_letters:snap_rect(game().dealt_letters.T.x, game().dealt_letters.T.y, hand_w, hand_h) end

	if game().dealt_letters.cards and game().dealt_letters.cards[1] then
		if game().dealt_letters.relayout then game().dealt_letters:relayout() end
		if game().dealt_letters.hard_set_cards then game().dealt_letters:hard_set_cards() end
	end

	snap_spatial(game().dealt_letters)
end

function M.stabilize()
	if not game().dealt_letters then return end
	M.apply_screen_position()
	if game().dealt_letters.cards and game().dealt_letters.cards[1] and game().dealt_letters.hard_set_cards then game().dealt_letters:hard_set_cards() end
end

return M