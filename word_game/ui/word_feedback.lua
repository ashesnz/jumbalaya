-- word_game/ui/word_feedback.lua - Word-play attention messages

local M = {}

local INVALID_WORD_TEXT = "Not a valid word!"

local function placement_area()
	return G.placement_table and G.placement_table.area
end

local function hand_dealt_metrics()
	if not G.hand then return nil end
	local left = G.hand.T.x
	local right = G.hand.T.x + G.hand.T.w
	local top = G.hand.T.y
	local bottom = G.hand.T.y + G.hand.T.h
	if G.hand_action_bar and not G.hand_action_bar.REMOVED then
		local bar = G.hand_action_bar
		right = math.max(right, bar.T.x + bar.T.w)
		top = math.min(top, bar.T.y)
		bottom = math.max(bottom, bar.T.y + bar.T.h)
	end
	local felt = get_table_felt_rect()
	local row_w = right - left
	local row_h = bottom - top
	return {
		cx = left + row_w * 0.5,
		cy = top + row_h * 0.5,
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

function M.show_above_hand_centered(text, colour, hold, offset_y)
	local row = hand_dealt_metrics()
	if not row then
		M.show(text, colour, hold, offset_y)
		return
	end
	if not spawn_attention then return end
	local card_h = G.CARD_H or G.hand.T.h or 1
	local zone_h = math.max(0.18, card_h * 0.34)
	local margin = math.max(0.06, card_h * 0.08)
	local cy = G.hand.T.y - margin - zone_h * 0.5
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

function M.show_invalid()
	M.show(INVALID_WORD_TEXT, G.C.RED, 1.6)
end

function M.is_invalid_reason(reason)
	return reason == "Not a valid word" or reason == "Does not match"
end

return M