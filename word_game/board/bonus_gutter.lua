--[[ word_game/board/bonus_gutter.lua - Bonus stack layout and drag/snap geometry ]]

local model = require("word_game.model.bonus_stack")
local placement_layout = require("word_game.ui.layout.placement")

local M = {}

M.LEFT_WINDOW_MARGIN = 0.14
M.STACK_Y_LIFT_PX = 20

local function window_left_x()
	return -((G.ROOM and G.ROOM.T and G.ROOM.T.x) or 0)
end

function M.stack_y_lift()
	local dim_ok, dim = pcall(require, "word_game.config.dimensions")
	local tile = G.TILESIZE or (dim_ok and dim.TILESIZE) or 20
	local scale = G.TILESCALE or (dim_ok and dim.TILESCALE) or 1
	local px_per_tile = tile * scale
	if px_per_tile <= 0 then
		px_per_tile = (dim_ok and dim.CANVAS_TILE_PX) or 73
	end
	return (M.STACK_Y_LIFT_PX or 20) / px_per_tile
end

function M.stack_layout()
	local timer = placement_layout.timeline_rect()
	local card_w = G.CARD_W or 1
	local card_h = G.CARD_H or 1.4
	local margin_x = M.LEFT_WINDOW_MARGIN
	local margin_y = math.max(0.10, card_h * 0.08)
	local lift = M.stack_y_lift()
	local x = window_left_x() + margin_x
	local y = timer.y + timer.h + margin_y - lift
	return {
		x = x,
		y = y,
		card_w = card_w,
		card_h = card_h,
		step_y = card_h * 0.5,
		clearance = math.max(0.45, card_w * 0.30),
		label_y = timer.y + timer.h + margin_y * 0.35 - lift,
	}
end

function M.target_position(index)
	local layout = M.stack_layout()
	return layout.x, layout.y + (index - 1) * layout.step_y
end

function M.point_in_stack(x, y)
	if not model.is_active() then return false end
	local layout = M.stack_layout()
	local count = math.max(1, #(model.cards() or {}))
	local pad_x = math.max(0.35, layout.card_w * 0.35)
	local pad_y = math.max(0.35, layout.card_h * 0.25)
	local top = layout.label_y - layout.card_h * 0.45
	local bottom = layout.y + (count - 1) * layout.step_y + layout.card_h + pad_y
	return x >= layout.x - pad_x
		and x <= layout.x + layout.card_w + pad_x
		and y >= top
		and y <= bottom
end

function M.drop_in_gutter(session, x, y)
	if M.point_in_stack(x, y) then return true end
	if not model.is_active() then return false end
	local area = session and session.area
	if not area or not area.T then return false end
	if x >= area.T.x then return false end
	local layout = M.stack_layout()
	local count = math.max(1, #(model.cards() or {}))
	local pad_y = math.max(0.35, layout.card_h * 0.25)
	local top = layout.label_y - layout.card_h * 0.55
	local bottom = layout.y + (count - 1) * layout.step_y + layout.card_h + pad_y
	local left = window_left_x()
	local right = layout.x + layout.card_w + math.max(0.35, layout.card_w * 0.35)
	return x >= left and x <= right and y >= top and y <= bottom
end

function M.return_card(card)
	if not card then return false end
	if not model.contains(card) then
		if card.bonus_card then
			model.add_card(card)
		else
			return false
		end
	end
	if card.area then
		if G.placement_table and card.area == G.placement_table.area
			and G.placement_table.on_remove_card then
			G.placement_table:on_remove_card(card)
		end
		if card.area.remove_card then
			card.area:remove_card(card)
		end
	end
	if card.states and card.states.drag then
		card.states.drag.is = false
	end
	if card.set_selected then
		card:set_selected(false)
	end
	local index = model.stack_index(card) or 1
	local tx, ty = M.target_position(index)
	if card.hard_set_T then
		card:hard_set_T(tx, ty, card.T.w, card.T.h)
	end
	card.T.r = 0
	return true
end

function M.gutter_pixels(layout)
	layout = layout or M.stack_layout()
	local count = math.max(1, #(model.cards() or {}))
	local pad_x = math.max(0.35, layout.card_w * 0.35)
	local pad_y = math.max(0.35, layout.card_h * 0.25)
	local top = layout.label_y - layout.card_h * 0.45
	local bottom = layout.y + (count - 1) * layout.step_y + layout.card_h + pad_y
	local ts = G.TILESCALE * G.TILESIZE
	return layout.x * ts - pad_x * ts,
		top * ts,
		(layout.card_w + pad_x * 2) * ts,
		(bottom - top) * ts
end

return M
