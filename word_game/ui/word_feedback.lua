-- word_game/ui/word_feedback.lua - Word-play attention messages

local M = {}

local INVALID_WORD_TEXT = "Not a valid word!"

local function placement_area()
	return G.placement_table and G.placement_table.area
end

local function hand_dealt_metrics()
	if not G.hand then return nil end

	local wr = G.GAME and G.GAME.word_round
	local locked = wr and wr.jumble and wr.jumble.locked_hand_layout
	local left, right, top, bottom

	if locked then
		left = locked.x
		right = locked.x + locked.w
		top = locked.y
		bottom = locked.y + locked.h
	elseif G.hand.cards and #G.hand.cards > 0 then
		for _, card in ipairs(G.hand.cards) do
			if card and card.T then
				local cl = card.T.x
				local cr = card.T.x + (card.T.w or G.CARD_W or 1)
				local ct = card.T.y
				local cb = card.T.y + (card.T.h or G.CARD_H or 1.4)
				left = left and math.min(left, cl) or cl
				right = right and math.max(right, cr) or cr
				top = top and math.min(top, ct) or ct
				bottom = bottom and math.max(bottom, cb) or cb
			end
		end
	end

	if not left then
		left = G.hand.T.x
		right = G.hand.T.x + G.hand.T.w
		top = G.hand.T.y
		bottom = G.hand.T.y + G.hand.T.h
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
		gap_w = math.min(math.max(row_w, G.hand.T.w), felt.w * 0.82),
		inner_h = math.max(row_h, G.hand.T.h),
	}
end

local function hand_gap_metrics()
	local area = placement_area()
	if not area or not G.hand then return nil end
	local felt = get_table_felt_rect()
	local top = area.T.y + area.T.h
	local bottom = G.hand.T.y
	if bottom <= top + 0.04 then
		bottom = top + math.max(0.28, (G.CARD_H or 1) * 0.32)
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

function M.show(text, colour, hold, offset_y)
	local gap = hand_gap_metrics()
	if not gap then
		if spawn_attention then
			spawn_attention({ text = text, scale = 0.5, hold = hold or 1.5,
				align = "cm", colour = colour or G.C.RED })
		end
		return
	end
	if not spawn_attention then return end
	local scale = math.min(0.68, math.max(0.36, gap.inner_h * 1.45))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = gap.gap_w,
		hold = hold or 1.5,
		align = "cm",
		major = G.ROOM_ATTACH,
		offset = {
			x = gap.cx - G.TILE_W * 0.5,
			y = gap.cy - G.TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or G.C.RED,
	})
end

function M.show_hand_centered(text, colour, hold, offset_y)
	local row = hand_dealt_metrics()
	if not row then
		M.show(text, colour, hold, offset_y)
		return
	end
	if not spawn_attention then return end
	local scale = math.min(0.72, math.max(0.38, row.inner_h * 1.35))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = row.gap_w,
		hold = hold or 1.5,
		align = "cm",
		major = G.ROOM_ATTACH,
		offset = {
			x = row.cx - G.TILE_W * 0.5,
			y = row.cy - G.TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or G.C.RED,
	})
end

function M.show_screen_centered(text, colour, hold, offset_y)
	if not spawn_attention then return end
	local scale = math.min(0.82, math.max(0.48, (G.TILE_H or 11) * 0.055))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = (G.TILE_W or 20) * 0.72,
		hold = hold or 1.2,
		align = "cm",
		major = G.ROOM_ATTACH,
		offset = {
			x = 0,
			y = offset_y or 0,
		},
		colour = colour or G.C.GOLD,
	})
end

function M.show_above_hand_centered(text, colour, hold, offset_y)
	local row = hand_dealt_metrics()
	if not row then
		M.show(text, colour, hold, offset_y)
		return
	end
	if not spawn_attention then return end
	local zone_h = math.max(0.18, row.inner_h * 0.34)
	local margin = math.max(0.06, row.inner_h * 0.08)
	local cy = row.top - margin - zone_h * 0.5
	local scale = math.min(0.78, math.max(0.42, zone_h * 1.55))
	spawn_attention({
		text = text,
		scale = scale,
		maxw = row.gap_w,
		hold = hold or 1.5,
		align = "cm",
		major = G.ROOM_ATTACH,
		offset = {
			x = row.cx - G.TILE_W * 0.5,
			y = cy - G.TILE_H * 0.5 + (offset_y or 0),
		},
		colour = colour or G.C.RED,
	})
end

function M.show_classic_proceed(opts)
	opts = opts or {}
	local RunMode = require("word_game.model.run_mode")
	M.show(RunMode.classic_proceed_message(), G.C.RED, opts.hold or 2.8, opts.offset_y or 0.15)
	local major = (G.placement_table and G.placement_table.area)
		or G.PLAY_ATTACH
		or G.ROOM_ATTACH
	if major and major.pulse then
		major:pulse(0.35, 0.2)
	end
end

function M.show_invalid()
	M.show(INVALID_WORD_TEXT, G.C.RED, 1.6)
end

function M.is_invalid_reason(reason)
	return reason == "Not a valid word" or reason == "Does not match"
end

function M.hand_dealt_metrics()
	return hand_dealt_metrics()
end

function M.lock_hand_layout(wr)
	if not wr or not wr.jumble then return end
	wr.jumble.locked_hand_layout = nil
	local metrics = hand_dealt_metrics()
	if not metrics then return end
	wr.jumble.locked_hand_layout = {
		x = metrics.left,
		y = metrics.top,
		w = metrics.w,
		h = metrics.h,
	}
end

return M