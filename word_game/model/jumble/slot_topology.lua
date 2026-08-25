--[[ word_game/model/jumble/slot_topology.lua - Pure slot topology (no screen coordinates) ]]

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
	j = j or (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state and WORD_GAME.Jumble.state())
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

function M.span_active_len(j)
	j = j or (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state and WORD_GAME.Jumble.state())
	if not j or not j.puzzle or j.puzzle.kind ~= "span" then return 3 end
	local puzzle = j.puzzle
	local before, after, single = M.span_parts(j.slots)
	if puzzle.center and before and after then
		local visible_before, visible_after = span_hand_counts(j, before, after, single)
		local anchor_tiles = #(puzzle.prefix or "") + #(puzzle.center or "") + #(puzzle.suffix or "")
		if anchor_tiles <= 0 then anchor_tiles = 1 end
		local active = anchor_tiles + visible_before + visible_after
		return math.min(puzzle.max, math.max(puzzle.min, active))
	end

	local middle = select(1, span_hand_counts(j, before, after, single))
	local anchor_tiles = #(puzzle.prefix or "") + #(puzzle.suffix or "")
	if anchor_tiles <= 0 then anchor_tiles = 1 end
	local active = anchor_tiles + middle
	return math.min(puzzle.max, math.max(puzzle.min, active))
end

function M.fixed_letter_items(j, active_len)
	local skew = M.FIXED_LETTER_SKEW
	local items = {}
	local has_first = false
	local has_last = false

	if not j or not j.slots then return items end

	local puzzle = j.puzzle
	if puzzle and puzzle.kind == "span" then
		active_len = active_len or M.span_active_len(j)
		if puzzle.prefix and #puzzle.prefix > 0 then
			has_first = true
			for k = 1, #puzzle.prefix do
				table.insert(items, {
					char = puzzle.prefix:sub(k, k),
					pos = k,
					position_label = tostring(k),
					anchor = "prefix",
				})
			end
		end
		if puzzle.center and #puzzle.center > 0 then
			local before = select(1, M.span_parts(j.slots))
			local center_start = M.center_slot_index(j, before and #(before.cards or {}) or 0)
			for k = 1, #puzzle.center do
				table.insert(items, {
					char = puzzle.center:sub(k, k),
					pos = center_start + k - 1,
					position_label = tostring(center_start + k - 1),
					anchor = "center",
				})
			end
		end
		if puzzle.suffix and #puzzle.suffix > 0 then
			has_last = true
			local n_suf = #puzzle.suffix
			for k = 1, n_suf do
				table.insert(items, {
					char = puzzle.suffix:sub(k, k),
					pos = active_len - n_suf + k,
					position_label = k == n_suf and "∞" or ("∞-" .. tostring(n_suf - k)),
					anchor = "suffix",
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

	-- Boss fixed letters stay upright; normal puzzles keep the fan skew.
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
