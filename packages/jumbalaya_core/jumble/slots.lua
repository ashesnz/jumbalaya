--[[ packages/jumbalaya_core/jumble/slots.lua - Slot model and word building (no G) ]]

local topology = require("jumbalaya_core.jumble.slot_topology")

local M = {}

local function parse_rigid_slots(pattern)
	local slots = {}
	for i = 1, #pattern do
		local ch = pattern:sub(i, i)
		if ch == "_" then
			slots[#slots + 1] = { kind = "blank", index = i, card = nil }
		else
			slots[#slots + 1] = { kind = "fixed", index = i, letter = ch }
		end
	end
	return slots
end

local function parse_span_slots(puzzle)
	local pre = puzzle.prefix or ""
	local suf = puzzle.suffix or ""
	local min_before, min_after, max_before, max_after, min_hand, max_hand = topology.span_limits(puzzle)
	local slots = {}
	if puzzle.prefix then
		slots[#slots + 1] = { kind = "fixed", index = 1, anchor = "prefix", letter = puzzle.prefix }
	end
	if puzzle.center then
		slots[#slots + 1] = {
			kind = "span",
			side = "before",
			index = #slots + 1,
			cards = {},
			min = min_before,
			max = max_before,
		}
		slots[#slots + 1] = {
			kind = "fixed",
			index = #slots + 1,
			anchor = "center",
			letter = puzzle.center,
			pin_index = puzzle.pin_index,
		}
		slots[#slots + 1] = {
			kind = "span",
			side = "after",
			index = #slots + 1,
			cards = {},
			min = min_after,
			max = max_after,
		}
	else
		slots[#slots + 1] = {
			kind = "span",
			index = #slots + 1,
			cards = {},
			min = min_hand,
			max = max_hand,
		}
	end
	if puzzle.suffix then
		slots[#slots + 1] = {
			kind = "fixed",
			index = #slots + 1,
			anchor = "suffix",
			letter = puzzle.suffix,
		}
	end
	return slots
end

local function parse_slots(puzzle)
	if puzzle.kind == "span" then
		return parse_span_slots(puzzle)
	end
	return parse_rigid_slots(puzzle.pattern)
end

function M.parse_slots(puzzle)
	return parse_slots(puzzle)
end

function M.span_slot(slots)
	local before, after, single, before_i, after_i, single_i = topology.span_parts(slots)
	if single then return single, single_i end
	if before then return before, before_i end
	if after then return after, after_i end
	return nil, nil
end

function M.blank_count(slots, puzzle)
	if puzzle and puzzle.kind == "span" then
		if puzzle.center then
			local before, after = topology.span_parts(slots)
			return (before and before.max or 0) + (after and after.max or 0)
		end
		local _, _, single = topology.span_parts(slots)
		return single and single.max or 0
	end
	local n = 0
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" then
			n = n + 1
		end
	end
	return n
end

local function letter_from_card(card, letter_fn)
	if letter_fn then
		return letter_fn(card)
	end
	if card and card.ability and card.ability.letter then
		return card.ability.letter
	end
	return nil
end

function M.build_word(slots, letter_fn)
	if not slots then return "" end
	local chars = {}
	for _, slot in ipairs(slots) do
		if slot.kind == "fixed" then
			for i = 1, #slot.letter do
				chars[#chars + 1] = slot.letter:sub(i, i)
			end
		elseif slot.kind == "span" then
			for _, card in ipairs(slot.cards or {}) do
				local letter = letter_from_card(card, letter_fn)
				if letter then
					chars[#chars + 1] = letter
				end
			end
		else
			local letter = letter_from_card(slot.card, letter_fn)
			if letter then
				chars[#chars + 1] = letter
			else
				return ""
			end
		end
	end
	return table.concat(chars)
end

function M.build_placement_preview_word(slots, letter_fn)
	if not slots then return "" end
	local chars = {}
	for _, slot in ipairs(slots) do
		if slot.kind == "fixed" then
			for i = 1, #slot.letter do
				chars[#chars + 1] = slot.letter:sub(i, i)
			end
		elseif slot.kind == "span" then
			for _, card in ipairs(slot.cards or {}) do
				local letter = letter_from_card(card, letter_fn)
				if letter then
					chars[#chars + 1] = letter
				end
			end
		elseif slot.kind == "blank" then
			if slot.card then
				local letter = letter_from_card(slot.card, letter_fn)
				if letter then
					chars[#chars + 1] = letter
				end
			end
		end
	end
	return table.concat(chars)
end

function M.all_blanks_filled(slots, puzzle)
	if puzzle and puzzle.kind == "span" then
		if puzzle.center then
			local before, after = topology.span_parts(slots)
			if not before or not after then return false end
			return #(before.cards or {}) >= (before.min or 0)
				and #(after.cards or {}) >= (after.min or 0)
		end
		local _, _, single = topology.span_parts(slots)
		if not single then return false end
		return #(single.cards or {}) >= (single.min or 1)
	end
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" and not slot.card then
			return false
		end
	end
	return true
end

function M.clear_blank_cards(slots)
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" then
			slot.card = nil
		elseif slot.kind == "span" then
			slot.cards = {}
		end
	end
end

return M
