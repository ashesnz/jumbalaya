--[[ word_game/ui/trade/columns.lua - Marketplace 5×3 grid (cards, modifiers, action rows) ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local preview = require("word_game.ui.trade.preview")
local offer_mod = require("word_game.ui.trade.offer")

local M = {}

local GRID_LAYER = 1
local GRID_ROWS = 5
local GRID_COLS = 3

-- Row heights as fractions of the overlay frame (sum = 1).
local ROW_HEIGHT_FRAC = {
	cards = 0.34,
	modifier = 0.14,
	button = 0.173333,
}

local function coin_sprite(size)
	if not Sprite then return nil end
	local atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.coin
	if not atlas or not atlas.image then return nil end
	local s = size or 0.32
	local sprite = Sprite(0, 0, s, s, atlas, { x = 0, y = 0 })
	sprite.states.drag.can = false
	sprite.states.hover.can = false
	sprite.states.collide.can = false
	sprite.states.click.can = false
	return sprite
end

local function token_row(cost)
	local nodes = {
		{ n = game().UI.TEXT, config = {
			text = tostring(cost),
			scale = 0.22,
			font = alpha_button_font(),
			colour = game().C.GOLD,
			shadow = false,
		}},
	}
	local coin = coin_sprite(0.22)
	if coin then
		nodes[#nodes + 1] = { n = game().UI.OBJECT, config = {
			object = coin,
			w = 0.22,
			h = 0.22,
			colour = game().C.WHITE,
			shadow = false,
		}}
	end
	return { n = game().UI.ROW, config = {
		align = "cm",
		padding = 0.02,
		colour = game().C.CLEAR,
		shadow = false,
	}, nodes = nodes }
end

local function action_button(label, cost, func_name, enabled, col_index)
	local g = game()
	local colour = enabled and g.C.UI.BUTTON or g.C.UI.BACKGROUND_INACTIVE
	local text_colour = enabled and g.C.UI.BUTTON_TEXT or g.C.UI.TEXT_INACTIVE
	local cfg = {
		align = "cm",
		minw = 0.82,
		minh = 0.34,
		padding = 0.03,
		r = 0.1,
		colour = colour,
		shadow = false,
		emboss = false,
		ref_table = { market_index = col_index },
	}
	if enabled then
		cfg.hover = true
		cfg.hover_colour = g.C.UI.BUTTON_HOVER
		cfg.button = func_name
	end
	return { n = g.UI.COLUMN, config = cfg, nodes = {
		{ n = g.UI.TEXT, config = {
			text = label,
			scale = 0.2,
			font = alpha_button_font(),
			colour = text_colour,
			shadow = false,
		}},
		token_row(cost),
	}}
end

local function grid_cell(nodes, col_w, min_h, id)
	return { n = game().UI.COLUMN, config = {
		id = id,
		align = "cm",
		minw = col_w,
		minh = min_h,
		padding = 0.01,
		colour = game().C.CLEAR,
		shadow = false,
	}, nodes = nodes }
end

local function modifier_label(letter)
	local deck = facade.deck()
	if not deck or not letter then return "" end
	return deck.modifier_description(letter) or deck.modifier_ui_text(letter) or ""
end

local function card_cell(item, index, col_w, row_h)
	local aspect = (game().CARD_H or 1.4) / (game().CARD_W or 1)
	local card_h = row_h * 0.9
	local card_w = math.min(col_w * 0.72, card_h / aspect)
	local card = preview.ensure(item, card_w, card_h)
	local nodes = {}
	if card then
		nodes[#nodes + 1] = { n = game().UI.OBJECT, config = {
			id = "trade_market_card_" .. index,
			object = card,
			w = card_w,
			h = card_h,
			colour = game().C.WHITE,
			shadow = false,
		}}
	else
		nodes[#nodes + 1] = { n = game().UI.TEXT, config = {
			text = item.letter or "?",
			scale = 0.7,
			colour = game().C.GOLD,
			shadow = true,
		}}
	end
	return grid_cell(nodes, col_w, row_h, "trade_market_cell_card_" .. index)
end

local function modifier_cell(item, index, col_w, row_h)
	local mod_text = modifier_label(item.letter)
	local text_colour = game().C.UI and game().C.UI.TEXT_LIGHT or game().C.WHITE
	return grid_cell({
		{ n = game().UI.TEXT, config = {
			id = "trade_market_modifier_" .. index,
			text = mod_text,
			scale = 0.14,
			maxw = col_w * 0.92,
			colour = text_colour,
			shadow = false,
		}},
	}, col_w, row_h, "trade_market_cell_modifier_" .. index)
end

local function column_row(row_id, col_w, row_h, items, cell_builder)
	local cells = {}
	for index = 1, GRID_COLS do
		local item = items[index]
		cells[#cells + 1] = cell_builder(item, index, col_w, row_h)
	end
	return { n = game().UI.ROW, config = {
		id = row_id,
		align = "cm",
		minw = col_w * GRID_COLS,
		minh = row_h,
		padding = 0.01,
		colour = game().C.CLEAR,
		shadow = false,
	}, nodes = cells }
end

local function action_row(row_id, label, cost, func_name, items, col_w, row_h, afford_fn)
	local cells = {}
	for index, item in ipairs(items) do
		cells[#cells + 1] = grid_cell({
			action_button(label, cost, func_name, afford_fn(item), index),
		}, col_w, row_h, row_id .. "_col_" .. index)
	end
	return { n = game().UI.ROW, config = {
		id = row_id,
		align = "cm",
		minw = col_w * GRID_COLS,
		minh = row_h,
		padding = 0.01,
		colour = game().C.CLEAR,
		shadow = false,
	}, nodes = cells }
end

function M.build_grid(frame)
	local trade = facade.trade()
	local costs = trade.ACTION_COSTS
	local items = offer_mod.items()
	while #items < GRID_COLS do
		items[#items + 1] = { letter = "?", mode = "market" }
	end

	local grid_h = frame.h
	local col_w = frame.w / GRID_COLS
	local cards_row_h = grid_h * ROW_HEIGHT_FRAC.cards
	local modifier_row_h = grid_h * ROW_HEIGHT_FRAC.modifier
	local button_row_h = grid_h * ROW_HEIGHT_FRAC.button

	local rows = {
		column_row("trade_marketplace_cards_row", col_w, cards_row_h, items, card_cell),
		column_row("trade_marketplace_modifier_row", col_w, modifier_row_h, items, modifier_cell),
		action_row(
			"trade_marketplace_add_row",
			"Add",
			costs.add,
			"trade_market_add",
			items,
			col_w,
			button_row_h,
			function(item) return trade.can_add(item) and trade.can_afford(costs.add) end
		),
		action_row(
			"trade_marketplace_remove_row",
			"Remove",
			costs.remove,
			"trade_market_remove",
			items,
			col_w,
			button_row_h,
			function(item) return trade.can_remove(item) and trade.can_afford(costs.remove) end
		),
		action_row(
			"trade_marketplace_modify_row",
			"Modify",
			costs.modifier,
			"trade_market_modify",
			items,
			col_w,
			button_row_h,
			function(item) return trade.can_modify(item) and trade.can_afford(costs.modifier) end
		),
	}

	return {
		n = game().UI.COLUMN,
		config = {
			id = "trade_marketplace_grid",
			draw_layer = GRID_LAYER,
			align = "cm",
			minw = frame.w,
			minh = frame.h,
			padding = 0.02,
			colour = game().C.CLEAR,
			shadow = false,
		},
		nodes = rows,
	}
end

function M.build_columns(frame)
	return M.build_grid(frame)
end

M.GRID_DRAW_LAYER = GRID_LAYER
M.GRID_ROWS = GRID_ROWS
M.GRID_COLS = GRID_COLS
M.ROW_HEIGHT_FRAC = ROW_HEIGHT_FRAC

return M
