--[[ word_game/ui/trade/layout.lua - marketplace modal geometry ]]

local game = require("word_game.ui.util.game_runtime").game

local Layout = require("word_game.ui.layout")

local M = {}

local DEFAULT_CARD_SCALE = 0.82
local MAX_COLUMNS = 3

--- Vertical offset (tiles) centreing the modal on the play-area felt.
function M.modal_offset_y()
	local felt = Layout.felt_rect and Layout.felt_rect()
	if not felt or not game().TILE_H then return 0 end
	return (felt.y + felt.h * 0.5) - game().TILE_H * 0.5 - 20 / (game().TILESIZE or 64)
end

--- Modal height (tiles) spans the play-area felt, top to bottom.
function M.modal_minh()
	local felt = Layout.felt_rect and Layout.felt_rect()
	return felt and felt.h or 1
end

--- Modal width (tiles) tracks the play column so card rows fit on all aspect ratios.
function M.modal_minw()
	local felt = Layout.felt_rect and Layout.felt_rect()
	return felt and math.max(felt.w, 8) or 12
end

function M.modal_padding()
	return 0.12
end

--- Up to three columns; fewer when the play column is narrow.
function M.column_count_for_items(item_count, modal_w)
	local n = math.max(1, item_count or 1)
	local columns = math.min(MAX_COLUMNS, n)
	local card_w = game().CARD_W or 1.4
	local min_col_w = card_w * 0.55 + 0.85
	modal_w = modal_w or M.modal_minw()
	while columns > 1 and columns * min_col_w > modal_w * 0.9 do
		columns = columns - 1
	end
	return columns
end

--- Shrink card art so the full grid fits inside the modal width.
function M.scale_for_grid(columns, modal_w, base_scale)
	base_scale = base_scale or DEFAULT_CARD_SCALE
	columns = math.max(1, columns or MAX_COLUMNS)
	modal_w = modal_w or M.modal_minw()
	local card_w = game().CARD_W or 1.4
	local col_pad = 0.7
	local gap = 0.12
	local usable = modal_w * 0.92
	local needed = columns * (card_w * base_scale + col_pad) + (columns - 1) * gap
	if needed <= usable then
		return base_scale
	end
	local scale = (usable - columns * col_pad - (columns - 1) * gap) / (columns * card_w)
	return math.max(0.52, math.min(base_scale, scale))
end

function M.grid_width(columns, market_card_scale)
	columns = math.max(1, columns or MAX_COLUMNS)
	local card_w = game().CARD_W or 1.4
	local col_w = card_w * market_card_scale + 0.7
	local gap = 0.12
	return columns * col_w + math.max(0, columns - 1) * gap
end

--- Minimum height for one card column (badge, card, modifier blurb, three actions).
function M.column_min_height(market_card_scale)
	local card_h = (game().CARD_H or 1.9) * market_card_scale
	local desc_block = 1.35
	local action_stack = 3 * 0.68 + 0.2
	local header = 0.55
	return header + card_h + desc_block + action_stack + 0.35
end

function M.body_min_height(market_card_scale, row_count)
	row_count = math.max(1, row_count or 1)
	local chrome = 0.55
	return chrome + row_count * M.column_min_height(market_card_scale) + (row_count - 1) * 0.15
end

--- @param item_count number
--- @param base_scale number|nil
--- @return table columns, scale, grid_w, column_minh, body_minh, modal_w
function M.market_layout_metrics(item_count, base_scale)
	local modal_w = M.modal_minw()
	local columns = M.column_count_for_items(item_count, modal_w)
	local scale = M.scale_for_grid(columns, modal_w, base_scale or DEFAULT_CARD_SCALE)
	local row_count = math.max(1, math.ceil((item_count or 0) / columns))
	return {
		modal_w = modal_w,
		columns = columns,
		scale = scale,
		grid_w = M.grid_width(columns, scale),
		column_minh = M.column_min_height(scale),
		body_minh = M.body_min_height(scale, row_count),
	}
end

function M.room_translate()
	local room = game() and game().ROOM
	if not room or not love or not love.graphics then return end
	local ts = (game().TILESCALE or 1) * (game().TILESIZE or 1)
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

return M
