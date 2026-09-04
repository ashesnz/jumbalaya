--[[
	app/startup/dealing.lua - TABLE_BOARD layout accessor globals.

	Thin adapters over WORD_GAME.Layout used by the app layer (display,
	window resize) and tests. Dealing and background staging live in the
	game packages (word_game/model/jumble_play/opening_deal.lua and
	word_game/ui/layout/backgrounds.lua).
]]

local Layout = require "word_game.ui.layout"

function get_play_area_rect()
	return {
		x = 0.8,
		y = 2.0,
		w = G.TILE_W - 1.6,
		h = G.TILE_H - 3.5,
	}
end

function get_table_board_sidebar_frac()
	if WORD_GAME and WORD_GAME.Layout then
		return WORD_GAME.Layout.sidebar_frac()
	end
	return (G.TABLE_BOARD_SIDEBAR_WIDTH or 3.0) / (G.TILE_W or 20)
end

function get_table_board_sidebar_width()
	if WORD_GAME and WORD_GAME.Layout then
		return WORD_GAME.Layout.sidebar_width()
	end
	return G.TABLE_BOARD_SIDEBAR_WIDTH or 3.0
end

function get_side_panel_inner_width()
	if WORD_GAME and WORD_GAME.Layout then
		return WORD_GAME.Layout.inner_width()
	end
	return get_table_board_sidebar_width() * 0.92
end

function update_table_board_panel_attach()
	if WORD_GAME and WORD_GAME.Layout then
		WORD_GAME.Layout.update_all()
	end
end

function get_table_felt_rect()
	if WORD_GAME and WORD_GAME.Layout then
		return WORD_GAME.Layout.felt_rect()
	end
	return {
		x = 0.8,
		y = 2.0,
		w = G.TILE_W - 1.6,
		h = G.TILE_H - 3.5,
	}
end

function apply_run_layout()
	if G.STAGE == G.STAGES.RUN and G.hand then
		Layout.set_screen_positions()
	end
end

function get_hand_area_width(hand_size)
	local spacing = G.HAND_CARD_SPACING or 0.78
	return G.CARD_W + math.max(hand_size - 1, 0) * G.CARD_W * spacing
end
