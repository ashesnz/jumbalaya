--[[ packages/jumbalaya_core/jumble/slot_topology.lua - Pure slot topology (no G, no screen coords) ]]

local M = {}

M.FIXED_LETTER_SKEW = 0.11

function M.span_parts(slots)
	local before, after, single
	local before_i, after_i, single_i
	for i, slot in ipairs(slots or {}) do
		if slot.kind == "span" then
			if slot.side == "before" then
				before, before_i = slot, i
			elseif slot.side == "after" then
				after, after_i = slot, i
			else
				single, single_i = slot, i
			end
		end
	end
	return before, after, single, before_i, after_i, single_i
end

function M.span_limits(puzzle)
	local pre = puzzle.prefix or ""
	local suf = puzzle.suffix or ""
	local center = puzzle.center or ""
	local fixed = #pre + #suf + #center
	local min_hand = math.max(0, puzzle.min - fixed)
	local max_hand = math.max(0, puzzle.max - fixed)
	if puzzle.center and puzzle.pin_index then
		local min_before = math.max(0, puzzle.pin_index - #pre - 1)
		local min_after = math.max(0, puzzle.min - puzzle.pin_index - #center - #suf + 1)
		local max_before = min_before
		local max_after = math.max(min_after, puzzle.max - puzzle.pin_index - #center - #suf + 1)
		return min_before, min_after, max_before, max_after, min_hand, max_hand
	end
	if puzzle.center then
		local min_before = math.floor(min_hand / 2)
		local min_after = min_hand - min_before
		local max_before = max_hand
		local max_after = max_hand
		return min_before, min_after, max_before, max_after, min_hand, max_hand
	end
	return 0, 0, max_hand, max_hand, min_hand, max_hand
end

function M.center_slot_index(j, before_count)
	local puzzle = j and j.puzzle
	if not puzzle or not puzzle.center then return 1 end
	before_count = before_count or 0
	if puzzle.pin_index then return puzzle.pin_index end
	if not puzzle.prefix and not puzzle.suffix then
		return math.floor(((puzzle.min or 3) - #puzzle.center) / 2) + 1
	end
	return #(puzzle.prefix or "") + before_count + 1
end

function M.span_active(j)
	return j and j.puzzle and j.puzzle.kind == "span"
end

function M.pattern_length(j)
	if not j or not j.puzzle then return 7 end
	if j.puzzle.kind == "span" then return j.puzzle.max or 7 end
	return #(j.puzzle.pattern or "")
end

local function span_hand_counts(j, before, after, single)
	if j.puzzle.center and before and after then
		local min_before = before.min or 0
		local min_after = after.min or 0
		local before_n = #(before.cards or {})
		local after_n = #(after.cards or {})
		return math.max(before_n, min_before), math.max(after_n, min_after)
	end

	local middle = single and #(single.cards or {}) or 0
	if middle == 0 then
		for _, slot in ipairs(j.slots or {}) do
			if slot.kind == "span" and not slot.side then
				middle = #(slot.cards or {})
				break
			end
		end
	end
	if middle == 0 then
		for _, slot in ipairs(j.slots or {}) do
			if slot.kind == "span" then
				middle = middle + #(slot.cards or {})
			end
		end
	end
	return middle, 0
end

local function compact_cards(list)
	local out = {}
	if not list then return out end
	local max_i = #list
	for k, _ in pairs(list) do
		if type(k) == "number" and k > max_i then
			max_i = k
		end
	end
	for i = 1, max_i do
		local card = list[i]
		if card ~= nil and not card.REMOVED then
			out[#out + 1] = card
		end
	end
	return out
end

local function collect_span_cards(j)
	local before, after, single = M.span_parts(j.slots)
	if j.puzzle and j.puzzle.center and before and after then
		local cards = {}
		for _, card in ipairs(compact_cards(before.cards)) do
			cards[#cards + 1] = card
		end
		for _, card in ipairs(compact_cards(after.cards)) do
			cards[#cards + 1] = card
		end
		return cards, before, after, single
	end
	if single then
		return compact_cards(single.cards), before, after, single
	end
	local cards = {}
	for _, slot in ipairs(j.slots or {}) do
		if slot.kind == "span" then
			for _, card in ipairs(compact_cards(slot.cards)) do
				cards[#cards + 1] = card
			end
		end
	end
	return cards, before, after, single
end

--- Live pattern-area cards override `span.cards` so a leftover letter from the
--- last Play does not keep an extra tile on the row.
local function placed_span_cards(j, extra_cards)
	local cards, before, after, single = collect_span_cards(j)
	if extra_cards ~= nil then
		cards = compact_cards(extra_cards)
	end
	return cards, before, after, single
end

--- Empty row: `_` pads to `puzzle.min` (C _ T). Any placed letter packs with no `_`.
function M.span_cells(j, extra_cards)
	if not j or not j.puzzle or j.puzzle.kind ~= "span" then
		return {}
	end
	local puzzle = j.puzzle
	local cards, before, after = placed_span_cards(j, extra_cards)
	local cells = {}
	local function push_fixed(text, anchor)
		for i = 1, #text do
			cells[#cells + 1] = { kind = "fixed", char = text:sub(i, i), anchor = anchor }
		end
	end
	local function push_cards(list)
		for i, card in ipairs(list or {}) do
			cells[#cells + 1] = { kind = "card", card = card, span_index = i }
		end
	end
	local function push_empties(n)
		for _ = 1, n do
			cells[#cells + 1] = { kind = "empty", char = "_" }
		end
	end

	if puzzle.center and before and after then
		local before_cards = compact_cards(before.cards)
		local after_cards = compact_cards(after.cards)
		local placed = #before_cards + #after_cards
		push_fixed(puzzle.prefix or "", "prefix")
		push_cards(before_cards)
		if placed == 0 then
			local visible_before, visible_after = span_hand_counts(j, before, after, nil)
			push_empties(math.max(0, visible_before - #before_cards))
			push_fixed(puzzle.center or "", "center")
			push_cards(after_cards)
			push_empties(math.max(0, visible_after - #after_cards))
		else
			push_fixed(puzzle.center or "", "center")
			push_cards(after_cards)
		end
		push_fixed(puzzle.suffix or "", "suffix")
		return cells
	end

	if puzzle.center then
		local pre = puzzle.prefix or ""
		local suf = puzzle.suffix or ""
		local center = puzzle.center or ""
		local min_len = puzzle.min or 3
		local center_idx = M.center_slot_index(j, 0)
		push_fixed(pre, "prefix")
		if #cards == 0 then
			push_empties(math.max(0, center_idx - 1 - #pre))
		end
		push_fixed(center, "center")
		if #cards == 0 then
			local used = #cells
			push_empties(math.max(0, min_len - used - #suf))
		end
		push_fixed(suf, "suffix")
		return cells
	end

	local pre = puzzle.prefix or ""
	local suf = puzzle.suffix or ""
	local n_cards = #cards
	local empties = 0
	if n_cards == 0 then
		empties = math.max(0, (puzzle.min or 3) - #pre - #suf)
	end
	push_fixed(pre, "prefix")
	push_cards(cards)
	push_empties(empties)
	push_fixed(suf, "suffix")
	local max_len = puzzle.max or 7
	while #cells > max_len do
		cells[#cells] = nil
	end
	return cells
end

--- How many letter tiles the play row should show right now.
function M.span_active_len(j, extra_cards)
	local cells = M.span_cells(j, extra_cards)
	if #cells > 0 then
		return #cells
	end
	if not j or not j.puzzle or j.puzzle.kind ~= "span" then
		return 3
	end
	return j.puzzle.min or 3
end

--- Index in `span.cards` for a drop on play-row cell `cell_i`.
--- `after_center` is true when the pointer is on the right half of that cell.
function M.span_insert_pos(j, cell_i, after_center, extra_cards)
	local cells = M.span_cells(j, extra_cards)
	if #cells == 0 then
		return 1
	end
	cell_i = math.max(1, math.min(#cells, tonumber(cell_i) or 1))
	local cards_before = 0
	for i = 1, cell_i - 1 do
		if cells[i].kind == "card" then
			cards_before = cards_before + 1
		end
	end
	local cell = cells[cell_i]
	if not cell then
		return cards_before + 1
	end
	if cell.kind == "empty" then
		return cards_before + 1
	end
	if cell.kind == "card" then
		if after_center then
			return cards_before + 2
		end
		return cards_before + 1
	end
	if cell.anchor == "prefix" then
		return 1
	end
	return cards_before + 1
end

function M.fixed_letter_items(j, active_len, extra_cards)
	local skew = M.FIXED_LETTER_SKEW
	local items = {}
	local has_first = false
	local has_last = false

	if not j or not j.slots then return items end

	local puzzle = j.puzzle
	if puzzle and puzzle.kind == "span" then
		local cells = M.span_cells(j, extra_cards)
		for i, cell in ipairs(cells) do
			if cell.kind == "fixed" then
				if cell.anchor == "prefix" and #items == 0 then
					has_first = true
				end
				if cell.anchor == "suffix" then
					has_last = true
				end
				local n_suf = #(puzzle.suffix or "")
				local suffix_k = cell.anchor == "suffix" and (i - (#cells - n_suf)) or nil
				table.insert(items, {
					char = cell.char,
					pos = i,
					position_label = cell.anchor == "suffix" and suffix_k == n_suf and "∞"
						or (cell.anchor == "suffix" and n_suf > 1 and ("∞-" .. tostring(n_suf - suffix_k)) or tostring(i)),
					anchor = cell.anchor,
				})
			end
		end
	else
		local total_slots = #j.slots
		for _, slot in ipairs(j.slots) do
			if slot.kind == "fixed" then
				if slot.index == 1 then
					has_first = true
				end
				if slot.index == total_slots then
					has_last = true
				end
				table.insert(items, {
					char = slot.letter or "",
					pos = slot.index,
					position_label = tostring(slot.index),
					anchor = "rigid",
				})
			end
		end
	end

	local n = #items
	if n == 0 then return items end

	if puzzle and puzzle.boss_word then
		return items
	end

	if has_first then
		items[1].rotation = -skew
		for i = 2, n - 1 do
			items[i].rotation = -items[i - 1].rotation
		end
		if n > 1 then
			if has_last then
				items[n].rotation = skew
			else
				items[n].rotation = -items[n - 1].rotation
			end
		end
	elseif has_last then
		items[n].rotation = skew
		for i = n - 1, 1, -1 do
			items[i].rotation = -items[i + 1].rotation
		end
	else
		items[1].rotation = -skew
		for i = 2, n do
			items[i].rotation = -items[i - 1].rotation
		end
	end

	return items
end

return M
