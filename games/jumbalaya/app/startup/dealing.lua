--[[
	app/startup/dealing.lua - TABLE_BOARD layout accessor globals.

	Thin adapters over word_game.ui.layout used by the app layer (display,
	window resize) and tests. Dealing and background staging live in the
	game packages (word_game/model/jumble_play/opening_deal.lua and
	word_game/ui/layout/backgrounds.lua).
]]

local BridgeRuntime = require("app.runtime")
local Layout = require "word_game.ui.layout"

local function game()
	return BridgeRuntime.game()
end

function get_play_area_rect()
	local g = game()
	return {
		x = 0.8,
		y = 2.0,
		w = g.TILE_W - 1.6,
		h = g.TILE_H - 3.5,
	}
end

function get_table_board_sidebar_frac()
	return Layout.sidebar_frac()
end

function get_table_board_sidebar_width()
	return Layout.sidebar_width()
end

function get_side_panel_inner_width()
	return Layout.inner_width()
end

function update_table_board_panel_attach()
	Layout.update_all()
end

function get_table_felt_rect()
	return Layout.felt_rect()
end

function apply_run_layout()
	local g = game()
	if g.STAGE == g.STAGES.RUN and g.dealt_letters then
		Layout.set_screen_positions()
	end
end

function get_hand_area_width(hand_size)
	local g = game()
	local spacing = g.HAND_CARD_SPACING or 0.78
	return g.CARD_W + math.max(hand_size - 1, 0) * g.CARD_W * spacing
end
