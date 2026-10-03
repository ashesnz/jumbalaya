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

local MARKET_CARD_SCALE = 0.5
local CARDS_ABOVE_BUTTON_GAP_PX = 10
local MODIFIER_ABOVE_CARD_GAP_PX = 12
local MODIFIER_ROW_HEIGHT_PX = 48
local ACTION_BUTTON_WIDTH_FRAC = 0.88
local ACTION_BUTTON_ROW_MINH = 0.44
local BUTTON_STACK_GAP_PX = 20

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

--- Row/column metrics that always fit inside `frame` (tiles).
function M.layout_metrics(frame)
	local frame_h = frame.h
	local frame_w = frame.w
	local col_w = frame_w / GRID_COLS
	local inner_h = frame_h - 2 * GRID_PADDING

	local market_w, market_h = market_card_dimensions()
	local cards_gap = marketplace_px_to_tiles(CARDS_ABOVE_BUTTON_GAP_PX)
	local cards_h = market_h + cards_gap

	local button_gap = marketplace_px_to_tiles(BUTTON_STACK_GAP_PX)
	local button_h = ACTION_BUTTON_ROW_MINH
	local button_stack_h = 3 * button_h + 2 * button_gap

	local modifier_gap = marketplace_px_to_tiles(MODIFIER_ABOVE_CARD_GAP_PX)
	local modifier_h = marketplace_px_to_tiles(MODIFIER_ROW_HEIGHT_PX)

	local content_h = modifier_h + modifier_gap + cards_h + button_stack_h
	if content_h > inner_h + 0.01 and content_h > 0 then
		local scale = inner_h / content_h
		modifier_h = modifier_h * scale
		modifier_gap = modifier_gap * scale
		cards_h = math.max(market_h * 0.5, cards_h * scale)
		button_h = button_h * scale
		button_gap = button_gap * scale
		button_stack_h = 3 * button_h + 2 * button_gap
		content_h = modifier_h + modifier_gap + cards_h + button_stack_h
	end
	local top_spacer_h = math.max(0, inner_h - content_h)
	local total_row_h = top_spacer_h + content_h

	local button_minw = col_w * ACTION_BUTTON_WIDTH_FRAC

	return {
		frame_w = frame_w,
		frame_h = frame_h,
		col_w = col_w,
		inner_h = inner_h,
		top_spacer_h = top_spacer_h,
		modifier_h = modifier_h,
		modifier_gap = modifier_gap,
		cards_h = cards_h,
		cards_gap = cards_gap,
		button_h = button_h,
		button_gap = button_gap,
		button_stack_h = button_stack_h,
		content_h = content_h,
		total_row_h = total_row_h,
		market_card_w = market_w,
		market_card_h = market_h,
		button_minw = button_minw,
	}
end

local function modifier_text_colour()
	return game().C.BLACK or { 0, 0, 0, 1 }
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
		minh = ACTION_BUTTON_ROW_MINH,
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

local function card_cell(item, index, col_w, row_h)
	local card_w, card_h = market_card_dimensions()
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
	return grid_cell(nodes, col_w, row_h, "trade_market_cell_card_" .. index, "bm")
end

local function modifier_cell(item, index, col_w, row_h)
	local mod_text = modifier_label(item.letter)
	return grid_cell({
		{ n = game().UI.TEXT, config = {
			id = "trade_market_modifier_" .. index,
			text = mod_text,
			scale = 0.2,
			maxw = col_w * 0.95,
			colour = modifier_text_colour(),
			shadow = false,
		}},
	}, col_w, row_h, "trade_market_cell_modifier_" .. index, "bm")
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
		padding = 0,
		colour = game().C.CLEAR,
		shadow = false,
	}, nodes = cells }
end

--- Empty ROW spacer — grid COLUMN only stacks ROW children vertically.
local function spacer_row(frame_w, gap_h, id)
	return { n = game().UI.ROW, config = {
		id = id,
		align = "cm",
		minw = frame_w,
		maxw = frame_w,
		minh = gap_h,
		colour = game().C.CLEAR,
		shadow = false,
	}, nodes = {} }
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

	local add_row = action_row(
		"trade_marketplace_add_row",
		"Add",
		costs.add,
		"trade_market_add",
		items,
		col_w,
		metrics.button_h,
		function(item) return trade.can_add(item) and trade.can_afford(costs.add) end
	)
	local remove_row = action_row(
		"trade_marketplace_remove_row",
		"Remove",
		costs.remove,
		"trade_market_remove",
		items,
		col_w,
		metrics.button_h,
		function(item) return trade.can_remove(item) and trade.can_afford(costs.remove) end
	)
	local modify_row = action_row(
		"trade_marketplace_modify_row",
		"Modify",
		costs.modifier,
		"trade_market_modify",
		items,
		col_w,
		metrics.button_h,
		function(item) return trade.can_modify(item) and trade.can_afford(costs.modifier) end
	)

	local rows = {}
	if metrics.top_spacer_h > 0.001 then
		rows[#rows + 1] = spacer_row(frame.w, metrics.top_spacer_h, "trade_marketplace_top_spacer")
	end
	rows[#rows + 1] = column_row("trade_marketplace_modifier_row", col_w, metrics.modifier_h, items, modifier_cell)
	rows[#rows + 1] = spacer_row(frame.w, metrics.modifier_gap, "trade_marketplace_modifier_card_gap")
	rows[#rows + 1] = column_row("trade_marketplace_cards_row", col_w, metrics.cards_h, items, card_cell)
	rows[#rows + 1] = add_row
	rows[#rows + 1] = spacer_row(frame.w, metrics.button_gap, "trade_marketplace_button_gap_1")
	rows[#rows + 1] = remove_row
	rows[#rows + 1] = spacer_row(frame.w, metrics.button_gap, "trade_marketplace_button_gap_2")
	rows[#rows + 1] = modify_row

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
M.GRID_PADDING = GRID_PADDING
M.ACTION_BUTTON_ROW_MINH = ACTION_BUTTON_ROW_MINH
M.BUTTON_STACK_GAP_PX = BUTTON_STACK_GAP_PX
M.hand_card_dimensions = hand_card_dimensions
M.market_card_dimensions = market_card_dimensions
M.MARKET_CARD_SCALE = MARKET_CARD_SCALE
M.CARDS_ABOVE_BUTTON_GAP_PX = CARDS_ABOVE_BUTTON_GAP_PX
M.MODIFIER_ABOVE_CARD_GAP_PX = MODIFIER_ABOVE_CARD_GAP_PX
M.MODIFIER_ROW_HEIGHT_PX = MODIFIER_ROW_HEIGHT_PX
M.modifier_text_colour = modifier_text_colour
M.ACTION_BUTTON_WIDTH_FRAC = ACTION_BUTTON_WIDTH_FRAC

return M
