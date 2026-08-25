--[[ word_game.board/layout.lua - Jumble placement row geometry and alignment. ]]

local config = require "word_game.board.config"
local jumble_geometry = require "word_game.board.jumble_geometry"

local M = {}

function M.area_width(ctx)
	return jumble_geometry.area_width(ctx)
end

function M.area_height(ctx)
	return ctx:card_h() * 0.95
end

function M.apply_screen_position(session)
	local area = session.area
	if not area then return end

	local ctx = session.ctx
	local felt = get_table_felt_rect()
	local pad_y = felt.h * config.ANCHOR_PAD_Y_FRAC

	area.T.w = M.area_width(ctx)
	area.T.h = M.area_height(ctx)
	area.T.x = felt.x + (felt.w - area.T.w) / 2

	local j = WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state
		and WORD_GAME.Jumble.state()
	if jumble_geometry.is_boss_row(j) and G.hand then
		local gap = math.max(0.28, ctx:card_h() * 0.22)
		area.T.y = G.hand.T.y - area.T.h - gap
	elseif jumble_geometry.span_active() and G.hand then
		area.T.y = jumble_geometry.anchor_y(felt, area.T.h, G.hand.T.y)
	else
		area.T.y = felt.y + pad_y
	end

	M.relayout(session)
	area:snap_VT()
	area:hard_set_cards()
end

---@return number px, number py, number pw, number ph canvas pixels (inside room translate_container)
function M.card_pixels(card)
	local t = card.VT or card.T
	local ts = G.TILESCALE * G.TILESIZE
	return t.x * ts, t.y * ts, t.w * ts, t.h * ts
end

---@return number px, number py, number pw, number ph canvas pixels (inside room translate_container)
function M.row_pixels(session)
	local area = session.area
	local ts = G.TILESCALE * G.TILESIZE
	return area.T.x * ts, area.T.y * ts, area.T.w * ts, area.T.h * ts
end

function M.point_in_area(session, x, y)
	local area = session.area
	if not area then return false end
	return x >= area.T.x and x <= area.T.x + area.T.w
		and y >= area.T.y and y <= area.T.y + area.T.h
end

function M.relayout(session)
	jumble_geometry.relayout(session)
end

return M
