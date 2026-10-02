--[[ word_game/ui/trade/columns.lua - Marketplace 5×3 grid (modifiers, cards, action rows) ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local preview = require("word_game.ui.trade.preview")
local offer_mod = require("word_game.ui.trade.offer")

local M = {}

local GRID_LAYER = 1
local GRID_ROWS = 5
local GRID_COLS = 3
local GRID_PADDING = 0.02

-- Relative row weights (normalized to fill the frame height).
local ROW_HEIGHT_FRAC = {
	modifier = 0.14,
	cards = 0.34,
	button = 0.17,
}

local MARKET_CARD_SCALE = 0.5
local CARD_ROW_DROP_PX = 50
local ACTION_BUTTON_WIDTH_FRAC = 0.88

local function marketplace_px_to_tiles(px)
	local g = game()
	local ts = (g.TILESIZE or 20) * (g.TILESCALE or 1)
	return px / ts
end

local function hand_card_dimensions()
	local g = game()
	return g.CARD_W or 1, g.CARD_H or 1.4
end

local function market_card_dimensions()
	local w, h = hand_card_dimensions()
	return w * MARKET_CARD_SCALE, h * MARKET_CARD_SCALE
end

local function row_weight_sum()
	return ROW_HEIGHT_FRAC.modifier + ROW_HEIGHT_FRAC.cards + 3 * ROW_HEIGHT_FRAC.button
end

--- Row/column metrics that always fit inside `frame` (tiles).
function M.layout_metrics(frame)
	local frame_h = frame.h
	local frame_w = frame.w
	local col_w = frame_w / GRID_COLS
	local inner_h = frame_h - 2 * GRID_PADDING
	local weight_sum = row_weight_sum()

	local modifier_h = inner_h * (ROW_HEIGHT_FRAC.modifier / weight_sum)
	local cards_h = inner_h * (ROW_HEIGHT_FRAC.cards / weight_sum)
	local button_h = inner_h * (ROW_HEIGHT_FRAC.button / weight_sum)
	local total_row_h = modifier_h + cards_h + 3 * button_h

	local _, market_h = market_card_dimensions()
	local card_drop_cap = marketplace_px_to_tiles(CARD_ROW_DROP_PX)
	local card_drop = math.min(card_drop_cap, math.max(0, cards_h - market_h * 1.02))

	local market_w, _ = market_card_dimensions()
	local button_minw = col_w * ACTION_BUTTON_WIDTH_FRAC

	return {
		frame_w = frame_w,
		frame_h = frame_h,
		col_w = col_w,
		inner_h = inner_h,
		modifier_h = modifier_h,
		cards_h = cards_h,
		card_drop = card_drop,
		button_h = button_h,
		total_row_h = total_row_h,
		market_card_w = market_w,
		market_card_h = market_h,
		button_minw = button_minw,
	}
end

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
			scale = 0.26,
			font = alpha_button_font(),
			colour = game().C.GOLD,
			shadow = false,
		}},
	}
	local coin = coin_sprite(0.26)
	if coin then
		nodes[#nodes + 1] = { n = game().UI.OBJECT, config = {
			object = coin,
			w = 0.26,
			h = 0.26,
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

local function action_button(label, cost, func_name, enabled, col_index, col_w)
	local g = game()
	local colour = enabled and g.C.UI.BUTTON or g.C.UI.BACKGROUND_INACTIVE
	local text_colour = enabled and g.C.UI.BUTTON_TEXT or g.C.UI.TEXT_INACTIVE
	local btn_w = col_w * ACTION_BUTTON_WIDTH_FRAC
	local cfg = {
		align = "cm",
		minw = btn_w,
		maxw = col_w * 0.96,
		minh = 0.44,
		padding = 0.035,
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
			scale = 0.24,
			font = alpha_button_font(),
			colour = text_colour,
			shadow = false,
		}},
		token_row(cost),
	}}
end

local function grid_cell(nodes, col_w, min_h, id, align)
	return { n = game().UI.COLUMN, config = {
		id = id,
		align = align or "cm",
		minw = col_w,
		maxw = col_w,
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

local function card_cell(item, index, col_w, row_h, card_drop)
	local card_w, card_h = market_card_dimensions()
	local card = preview.ensure(item, card_w, card_h)
	local nodes = {
		{ n = game().UI.BOX, config = {
			w = 0.01,
			h = card_drop,
			colour = game().C.CLEAR,
			shadow = false,
		}},
	}
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
	return grid_cell(nodes, col_w, row_h, "trade_market_cell_card_" .. index, "m")
end

local function modifier_cell(item, index, col_w, row_h)
	local mod_text = modifier_label(item.letter)
	local text_colour = game().C.UI and game().C.UI.TEXT_LIGHT or game().C.WHITE
	return grid_cell({
		{ n = game().UI.TEXT, config = {
			id = "trade_market_modifier_" .. index,
			text = mod_text,
			scale = 0.2,
			maxw = col_w * 0.95,
			colour = text_colour,
			shadow = false,
		}},
	}, col_w, row_h, "trade_market_cell_modifier_" .. index)
end

local function column_row(row_id, col_w, row_h, items, cell_builder, ...)
	local cells = {}
	for index = 1, GRID_COLS do
		local item = items[index]
		cells[#cells + 1] = cell_builder(item, index, col_w, row_h, ...)
	end
	return { n = game().UI.ROW, config = {
		id = row_id,
		align = "cm",
		minw = col_w * GRID_COLS,
		maxw = col_w * GRID_COLS,
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
			action_button(label, cost, func_name, afford_fn(item), index, col_w),
		}, col_w, row_h, row_id .. "_col_" .. index)
	end
	return { n = game().UI.ROW, config = {
		id = row_id,
		align = "cm",
		minw = col_w * GRID_COLS,
		maxw = col_w * GRID_COLS,
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

	local metrics = M.layout_metrics(frame)
	local col_w = metrics.col_w

	local rows = {
		column_row("trade_marketplace_modifier_row", col_w, metrics.modifier_h, items, modifier_cell),
		column_row("trade_marketplace_cards_row", col_w, metrics.cards_h, items, card_cell, metrics.card_drop),
		action_row(
			"trade_marketplace_add_row",
			"Add",
			costs.add,
			"trade_market_add",
			items,
			col_w,
			metrics.button_h,
			function(item) return trade.can_add(item) and trade.can_afford(costs.add) end
		),
		action_row(
			"trade_marketplace_remove_row",
			"Remove",
			costs.remove,
			"trade_market_remove",
			items,
			col_w,
			metrics.button_h,
			function(item) return trade.can_remove(item) and trade.can_afford(costs.remove) end
		),
		action_row(
			"trade_marketplace_modify_row",
			"Modify",
			costs.modifier,
			"trade_market_modify",
			items,
			col_w,
			metrics.button_h,
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
			maxw = frame.w,
			minh = frame.h,
			maxh = frame.h,
			padding = GRID_PADDING,
			colour = game().C.CLEAR,
			shadow = false,
		},
		nodes = rows,
	}
end

function M.build_columns(frame)
	return M.build_grid(frame)
end

function M.sum_row_min_heights(grid_def)
	local total = 0
	for _, row in ipairs(grid_def.nodes or {}) do
		total = total + (row.config and row.config.minh or 0)
	end
	return total
end

M.GRID_DRAW_LAYER = GRID_LAYER
M.GRID_ROWS = GRID_ROWS
M.GRID_COLS = GRID_COLS
M.ROW_HEIGHT_FRAC = ROW_HEIGHT_FRAC
M.GRID_PADDING = GRID_PADDING
M.hand_card_dimensions = hand_card_dimensions
M.market_card_dimensions = market_card_dimensions
M.MARKET_CARD_SCALE = MARKET_CARD_SCALE
M.CARD_ROW_DROP_PX = CARD_ROW_DROP_PX
M.ACTION_BUTTON_WIDTH_FRAC = ACTION_BUTTON_WIDTH_FRAC

return M
