--[[ word_game/model/jumble/slots.lua - Placement row slots (G glue over jumbalaya_core) ]]

local live_game = require("word_game.model.live_game")

return function(M)

local bonus_return = require("word_game.model.jumble.bonus_return")
local core = require("jumbalaya_core.jumble.slots")
local topology = require("jumbalaya_core.jumble.slot_topology")

local function letter_fn(card)
	if Dictionary then
		return Dictionary.letter_from_card(card)
	end
	return card and card.ability and card.ability.letter
end

local function geometry(session)
	if session and session.jumble_geometry then
		return session.jumble_geometry
	end
	local pt = live_game().pattern_row
	return pt and pt.jumble_geometry
end

M.parse_slots = core.parse_slots
M.span_slot = core.span_slot
M.blank_count = core.blank_count
M.clear_blank_cards = core.clear_blank_cards

function M.build_word(slots)
	return core.build_word(slots, letter_fn)
end

function M.build_placement_preview_word(slots)
	return core.build_placement_preview_word(slots, letter_fn)
end

M.all_blanks_filled = core.all_blanks_filled

function M.sync_placement_cards(slots)
	local area = live_game().pattern_row and live_game().pattern_row.area
	if not area then return end
	area.cards = {}
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" and slot.card then
			area.cards[#area.cards + 1] = slot.card
		elseif slot.kind == "span" then
			for _, card in ipairs(slot.cards or {}) do
				area.cards[#area.cards + 1] = card
			end
		end
	end
	area:hard_set_cards()
end

function M.blank_slot_index_for_x(session, x)
	local j = M.state()
	if not j or not j.slots then return nil end
	local geo = geometry(session)
	if not geo then return nil end
	if j.puzzle and j.puzzle.kind == "span" then
		local before, after, single, before_i, after_i, single_i = topology.span_parts(j.slots)
		if j.puzzle.center and before and after then
			local center_idx = topology.center_slot_index(j, #(before.cards or {}))
			local before_limit = math.min(before.max or 0, center_idx - 1 - #(j.puzzle.prefix or ""))
			local after_limit = after.max or 0
			if #(before.cards or {}) >= before_limit and #(after.cards or {}) >= after_limit then
				return nil
			end
			local active_len = topology.span_active_len(j)
			local centers = geo.span_centers(session, active_len)
			local center_end_idx = center_idx + #(j.puzzle.center or "") - 1
			local center_mid = (centers[center_idx] + (centers[center_end_idx] or centers[center_idx])) / 2
			if x <= center_mid then
				if #(before.cards or {}) < before_limit then
					return before_i, #(before.cards or {}) + 1
				end
				if #(after.cards or {}) < after_limit then
					return after_i, #(after.cards or {}) + 1
				end
			else
				if #(after.cards or {}) < after_limit then
					return after_i, #(after.cards or {}) + 1
				end
				if #(before.cards or {}) < before_limit then
					return before_i, #(before.cards or {}) + 1
				end
			end
			return nil
		end
		local span, span_i = single, single_i
		if not span then return nil end
		if #(span.cards or {}) >= (span.max or 0) then
			return nil
		end
		local active_len = topology.span_active_len(j)
		local centers = geo.span_centers(session, active_len)
		local puzzle = j.puzzle
		local card_start = #(puzzle.prefix or "") + 1
		local card_end = active_len - #(puzzle.suffix or "")
		local n_cards = #(span.cards or {})
		local insert_pos = n_cards + 1
		if n_cards > 0 and card_end >= card_start then
			if x <= centers[card_start] then
				insert_pos = 1
			elseif x >= centers[card_start + n_cards - 1] then
				insert_pos = n_cards + 1
			elseif n_cards > 1 then
				for i = 1, n_cards - 1 do
					local left = card_start + i - 1
					local right = card_start + i
					local mid = (centers[left] + centers[right]) / 2
					if x < mid then
						insert_pos = i
						break
					else
						insert_pos = i + 1
					end
				end
			end
		end
		return span_i, insert_pos
	end

	local slot_i = geo.slot_index_at_x(session, x)
	if not slot_i then return nil end
	local slot = j.slots[slot_i]
	if slot and slot.kind == "blank" then
		return slot_i
	end
	return nil
end

function M.first_empty_blank()
	local j = M.state()
	if not j then return nil end
	if j.puzzle and j.puzzle.kind == "span" then
		if j.puzzle.center then
			local before, after, _, before_i, after_i = topology.span_parts(j.slots)
			if not before or not after then return nil end
			local center_idx = topology.center_slot_index(j, #(before.cards or {}))
			local before_limit = math.min(before.max or 0, center_idx - 1 - #(j.puzzle.prefix or ""))
			if before and #(before.cards or {}) < before_limit then
				return before_i
			end
			if after and #(after.cards or {}) < (after.max or 0) then
				return after_i
			end
			return nil
		end
		local span, span_i = M.span_slot(j.slots)
		if span and #(span.cards or {}) < (span.max or 0) then
			return span_i
		end
		return nil
	end
	for i, slot in ipairs(j.slots) do
		if slot.kind == "blank" and not slot.card then
			return i
		end
	end
	return nil
end

local function detach_card_from_slots(slots, card)
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" and slot.card == card then
			slot.card = nil
		elseif slot.kind == "span" then
			for i = #(slot.cards or {}), 1, -1 do
				if slot.cards[i] == card then
					table.remove(slot.cards, i)
				end
			end
		end
	end
end

function M.slot_for_card(card)
	local j = M.state()
	if not j or not j.slots or not card then return nil end
	for i, slot in ipairs(j.slots) do
		if slot.kind == "blank" and slot.card == card then
			return i, nil
		elseif slot.kind == "span" then
			for pi, span_card in ipairs(slot.cards or {}) do
				if span_card == card then
					return i, pi
				end
			end
		end
	end
	return nil
end

function M.assign_card_to_blank(slot_index, card, insert_pos)
	local j = M.state()
	if not j or not j.slots then return false end
	local slot = j.slots[slot_index]
	if not slot then return false end
	if j.puzzle and j.puzzle.kind == "span" and j.puzzle.center then
		local before, after, _, before_i, after_i = topology.span_parts(j.slots)
		if before and after and (slot_index == before_i or slot_index == after_i) then
			local center_idx = topology.center_slot_index(j, #(before.cards or {}))
			local before_limit = math.min(before.max or 0, center_idx - 1 - #(j.puzzle.prefix or ""))
			local after_limit = after.max or 0
			if slot_index == before_i and #(before.cards or {}) >= before_limit then
				if #(after.cards or {}) < after_limit then
					slot_index = after_i
					slot = after
					insert_pos = nil
				else
					return false
				end
			elseif slot_index == after_i and #(after.cards or {}) >= after_limit then
				if #(before.cards or {}) < before_limit then
					slot_index = before_i
					slot = before
					insert_pos = nil
				else
					return false
				end
			end
		end
	end

	if slot.kind == "span" then
		detach_card_from_slots(j.slots, card)
		if #(slot.cards or {}) >= (slot.max or 0) then
			return false
		end
		slot.cards = slot.cards or {}
		if insert_pos and insert_pos >= 1 and insert_pos <= #slot.cards + 1 then
			table.insert(slot.cards, insert_pos, card)
		else
			slot.cards[#slot.cards + 1] = card
		end
	elseif slot.kind == "blank" then
		if slot.card and slot.card ~= card then
			local displaced = slot.card
			if displaced.bonus_card then
				bonus_return.return_card(displaced)
			elseif live_game().dealt_letters and displaced.area ~= live_game().dealt_letters then
				live_game().dealt_letters:emplace(displaced)
			end
		end
		detach_card_from_slots(j.slots, card)
		slot.card = card
	else
		return false
	end

	if live_game().pattern_row and live_game().pattern_row.area and card.set_card_area then
		card:set_card_area(live_game().pattern_row.area)
	end
	M.sync_placement_cards(j.slots)
	if live_game().pattern_row then
		live_game().pattern_row:relayout()
		if live_game().pattern_row.area then
			live_game().pattern_row.area:hard_set_cards()
		end
	end
	return true
end

function M.remove_card_from_blanks(card)
	local j = M.state()
	if not j then return end
	detach_card_from_slots(j.slots, card)
	M.sync_placement_cards(j.slots)
	if live_game().pattern_row then
		live_game().pattern_row:relayout()
		if live_game().pattern_row.area then
			live_game().pattern_row.area:hard_set_cards()
		end
	end
end
end
