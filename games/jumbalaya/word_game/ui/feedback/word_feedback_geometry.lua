--[[ word_game/ui/feedback/word_feedback_geometry.lua - Board attention text layout metrics ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local shell = facade.shell()

local M = {}

function M.placement_area()
	local row = shell.pattern_row()
	return row and row.area
end

function M.hand_dealt_metrics()
	local dealt = shell.dealt_letters()
	if not dealt then return nil end

	local wr = game_access.word_round()
	local locked = wr and wr.jumble and wr.jumble.locked_hand_layout
	local left, right, top, bottom

	if locked then
		left = locked.x
		right = locked.x + locked.w
		top = locked.y
		bottom = locked.y + locked.h
	elseif dealt.cards and #dealt.cards > 0 then
		for _, card in ipairs(dealt.cards) do
			if card and card.T then
				local cl = card.T.x
				local cr = card.T.x + (card.T.w or game().CARD_W or 1)
				local ct = card.T.y
				local cb = card.T.y + (card.T.h or game().CARD_H or 1.4)
				left = left and math.min(left, cl) or cl
				right = right and math.max(right, cr) or cr
				top = top and math.min(top, ct) or ct
				bottom = bottom and math.max(bottom, cb) or cb
			end
		end
	end

	if not left then
		if not dealt.T then return nil end
		left = dealt.T.x
		right = dealt.T.x + dealt.T.w
		top = dealt.T.y
		bottom = dealt.T.y + dealt.T.h
	end

	local row_w = right - left
	local row_h = bottom - top
	local felt = get_table_felt_rect()
	return {
		cx = left + row_w * 0.5,
		cy = top + row_h * 0.5,
		left = left,
		top = top,
		w = row_w,
		h = row_h,
		bottom = bottom,
		gap_w = math.min(math.max(row_w, dealt.T.w), felt.w * 0.82),
		inner_h = math.max(row_h, dealt.T.h),
	}
end

function M.hand_gap_metrics()
	local area = M.placement_area()
	local dealt = shell.dealt_letters()
	if not area or not area.T or not dealt or not dealt.T then return nil end
	local felt = get_table_felt_rect()
	local top = area.T.y + area.T.h
	local bottom = dealt.T.y
	if bottom <= top + 0.04 then
		bottom = top + math.max(0.28, (game().CARD_H or 1) * 0.32)
	end
	local gap = bottom - top
	local pad = math.max(0.08, gap * 0.22)
	local inner_h = math.max(0.12, gap - pad * 2)
	return {
		cx = felt.x + felt.w * 0.5,
		cy = top + pad + inner_h * 0.5,
		gap_w = math.min(area.T.w, felt.w * 0.82),
		inner_h = inner_h,
	}
end

return M
