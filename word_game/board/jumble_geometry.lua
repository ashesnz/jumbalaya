--[[ word_game.board/jumble_geometry.lua - Jumble row screen geometry and card alignment ]]

local config = require "word_game.board.config"
local topology = require "word_game.model.jumble.slot_topology"

local M = {}

local SPAN_HAND_GAP = 0.7
local SPAN_SLOT_GAP = 0.07
local SPAN_SLOT_SPACING = 1.0 + SPAN_SLOT_GAP
local STANDARD_ROW_SLOTS = 7

local function row_slot_cap()
	return (G and G.TABLE_HAND_SIZE) or STANDARD_ROW_SLOTS
end

local function jumble_state()
	if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state then
		return WORD_GAME.Jumble.state()
	end
	return nil
end

local function is_boss_row(j)
	j = j or jumble_state()
	return j and j.boss_word_active and j.puzzle and j.puzzle.boss_word
end

function M.is_boss_row(j)
	return is_boss_row(j)
end

function M.boss_slot_spacing()
	return config.boss_slot_spacing()
end

local function boss_felt_width()
	if get_table_felt_rect then
		local felt = get_table_felt_rect()
		return felt and felt.w
	end
	return nil
end

local function boss_row_metrics(ctx, count)
	local card_w = ctx:card_w()
	local preferred_spacing = M.boss_slot_spacing()
	local min_spacing = 1.0 + math.max(0.04, (config.BOSS_SLOT_GAP_FRAC or 0.14) * 0.35)
	local edge = 2 * card_w * config.ROW_EDGE_PADDING
	local max_w = boss_felt_width()
	local spacing = preferred_spacing
	local group_w = M.group_width(card_w, count, spacing)
	local total = group_w + edge
	if max_w and total > max_w and count > 1 then
		local avail_group = math.max(card_w, max_w - edge)
		local tight_spacing = math.max(1.01, (avail_group - card_w) / ((count - 1) * card_w))
		if M.group_width(card_w, count, preferred_spacing) + edge <= max_w then
			spacing = preferred_spacing
		else
			spacing = tight_spacing
		end
		group_w = M.group_width(card_w, count, spacing)
		total = math.min(max_w, group_w + edge)
	end
	return total, spacing, card_w, group_w
end

local function slot_card_dims(session)
	local card_w = session.ctx:card_w()
	local card_h = session.ctx:card_h()
	local area = session.area
	if area and area.cards and area.cards[1] then
		card_w = area.cards[1].T.w
		card_h = area.cards[1].T.h
	end
	return card_w, card_h
end

function M.span_active()
	return topology.span_active(jumble_state())
end

function M.hand_clearance(card_h)
	return (card_h or G.CARD_W) * SPAN_HAND_GAP
end

function M.anchor_y(felt, area_h, hand_top)
	local pad_y = felt.h * config.ANCHOR_PAD_Y_FRAC
	return math.max(felt.y + pad_y, felt.y + felt.h * 0.015)
end

function M.pattern_length()
	return topology.pattern_length(jumble_state())
end

function M.span_active_len(j)
	return topology.span_active_len(j or jumble_state())
end

function M.slot_count()
	local j = jumble_state()
	if j and j.puzzle and j.puzzle.kind == "span" then
		return j.puzzle.max
	end
	return M.pattern_length()
end

function M.card_row_y(area, card_h)
	return area.T.y + area.T.h / 2 - card_h / 2
end

function M.group_width(card_w, count, spacing)
	if count <= 1 then return card_w end
	return card_w + (count - 1) * card_w * spacing
end

function M.area_width(ctx)
	local slots = M.slot_count()
	local j = jumble_state()
	if j and j.puzzle and j.puzzle.kind == "span" then
		local spacing = SPAN_SLOT_SPACING
		local group_w = M.group_width(ctx:card_w(), slots, spacing)
		return group_w + 2 * ctx:card_w() * config.ROW_EDGE_PADDING
	end
	if is_boss_row(j) then
		local total = boss_row_metrics(ctx, M.slot_count())
		return total
	end
	-- Non-boss rigid rows longer than the hand cap compress into seven-card width.
	local cap = row_slot_cap()
	if slots > cap then
		slots = cap
	end
	return ctx:card_w() * config.row_width_for_slots(slots)
end

function M.span_centers(session, active_len)
	local area = session.area
	if not area then return {} end
	local card_w = slot_card_dims(session)
	local spacing = SPAN_SLOT_SPACING
	local group_w = M.group_width(card_w, active_len, spacing)
	local start_x = area.T.x + (area.T.w - group_w) / 2
	local centers = {}
	for i = 1, active_len do
		centers[i] = start_x + (i - 1) * card_w * spacing + card_w * 0.5
	end
	return centers
end

function M.slot_centers(session)
	local j = jumble_state()
	if j and j.puzzle and j.puzzle.kind == "span" then
		return M.span_centers(session, M.span_active_len(j))
	end

	local area = session.area
	if not area then return {} end
	local count = M.slot_count()
	if is_boss_row(j) then
		local card_w = slot_card_dims(session)
		local _, spacing, _, group_w = boss_row_metrics(session.ctx, count)
		local start_x = area.T.x + (area.T.w - group_w) / 2
		local centers = {}
		for i = 1, count do
			centers[i] = start_x + (i - 1) * card_w * spacing + card_w * 0.5
		end
		return centers
	end
	local cap = row_slot_cap()
	local card_w = session.ctx:card_w()
	local spacing = config.card_spacing()
	local group_w = M.group_width(card_w, count, spacing)
	if count > cap then
		card_w = slot_card_dims(session)
		group_w = M.group_width(card_w, cap, spacing)
		spacing = count <= 1 and 0 or (group_w - card_w) / ((count - 1) * card_w)
	end
	local start_x = area.T.x + (area.T.w - group_w) / 2
	local centers = {}
	for i = 1, count do
		centers[i] = start_x + (i - 1) * card_w * spacing + card_w * 0.5
	end
	return centers
end

function M.slot_index_at_x(session, x)
	local centers = M.slot_centers(session)
	local card_w = slot_card_dims(session)
	local best_i, best_d
	for i, cx in ipairs(centers) do
		local d = math.abs(x - cx)
		if not best_d or d < best_d then
			best_d = d
			best_i = i
		end
	end
	if best_i and best_d and best_d <= card_w * 0.65 then
		return best_i
	end
	return nil
end

function M.relayout(session)
	local j = jumble_state()
	local area = session.area
	if not j or not j.slots or not area then
		return
	end

	local function snap_card(card)
		if card and card.hard_set_T then
			card:hard_set_T(card.T.x, card.T.y, card.T.w, card.T.h)
		end
	end

	local span_cards = {}
	for _, slot in ipairs(j.slots) do
		if slot.kind == "blank" and slot.card then
			span_cards[#span_cards + 1] = slot.card
		elseif slot.kind == "span" then
			for _, card in ipairs(slot.cards or {}) do
				span_cards[#span_cards + 1] = card
			end
		end
	end

	if j.puzzle and j.puzzle.kind == "span" then
		local card_w = slot_card_dims(session)
		local active_len = M.span_active_len(j)
		local centers = M.span_centers(session, active_len)
		local puzzle = j.puzzle
		local before, after, single = topology.span_parts(j.slots)
		if puzzle.center and before and after then
			local before_n = #(before.cards or {})
			local after_n = #(after.cards or {})
			local center_idx = topology.center_slot_index(j, before_n)
			local after_start = center_idx + #(puzzle.center or "")
			for i, card in ipairs(before.cards or {}) do
				if not card.states.drag.is then
					local cx = centers[center_idx - before_n + i - 1]
					if cx then
						card.T.r = 0
						card.T.x = cx - card_w * 0.5
						card.T.y = M.card_row_y(area, card.T.h)
						snap_card(card)
					end
				end
			end
			for i, card in ipairs(after.cards or {}) do
				if not card.states.drag.is then
					local cx = centers[after_start + i - 1]
					if cx then
						card.T.r = 0
						card.T.x = cx - card_w * 0.5
						card.T.y = M.card_row_y(area, card.T.h)
						snap_card(card)
					end
				end
			end
		else
			local card_offset = #(puzzle.prefix or "")
			for i, card in ipairs(span_cards) do
				if not card.states.drag.is then
					local cx = centers[i + card_offset]
					if cx then
						card.T.r = 0
						card.T.x = cx - card_w * 0.5
						card.T.y = M.card_row_y(area, card.T.h)
						snap_card(card)
					end
				end
			end
		end
	else
		local centers = M.slot_centers(session)
		for _, slot in ipairs(j.slots) do
			if slot.kind == "blank" and slot.card then
				local card = slot.card
				if not card.states.drag.is then
					local cx = centers[slot.index]
					if cx then
						card.T.r = 0
						card.T.x = cx - card.T.w / 2
						card.T.y = M.card_row_y(area, card.T.h)
						snap_card(card)
					end
				end
			end
		end
	end
end

return M
