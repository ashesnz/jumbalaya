--[[ packages/jumbalaya_core/store/immutable.lua - Shallow copy helpers for immutable reducers ]]

local M = {}

function M.shallow_copy(t)
	if type(t) ~= "table" then return t end
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end

function M.shallow_state(state)
	return M.shallow_copy(state)
end

function M.copy_slot(slot)
	if not slot then return nil end
	local out = M.shallow_copy(slot)
	if slot.cards then
		out.cards = M.shallow_copy(slot.cards)
	end
	return out
end

function M.copy_jumble_slots(slots)
	if not slots then return nil end
	local out = {}
	for i, slot in ipairs(slots) do
		out[i] = M.copy_slot(slot)
	end
	return out
end

function M.copy_word_round(wr)
	if not wr then return nil end
	local out = M.shallow_copy(wr)
	if wr.played_words then
		out.played_words = M.shallow_copy(wr.played_words)
	end
	if wr.jumble then
		out.jumble = M.shallow_copy(wr.jumble)
		if wr.jumble.puzzle_words then
			out.jumble.puzzle_words = M.shallow_copy(wr.jumble.puzzle_words)
		end
		if wr.jumble.slots then
			out.jumble.slots = M.copy_jumble_slots(wr.jumble.slots)
		end
		if wr.jumble.pending_boss then
			out.jumble.pending_boss = M.shallow_copy(wr.jumble.pending_boss)
		end
	end
	return out
end

function M.copy_run_state(rs)
	if not rs then return nil end
	local out = M.shallow_copy(rs)
	if rs.perks then
		out.perks = M.shallow_copy(rs.perks)
	end
	if rs.stats then
		out.stats = M.shallow_copy(rs.stats)
	end
	return out
end

function M.copy_pile(pile)
	if not pile then return {} end
	local out = {}
	for k, v in pairs(pile) do
		out[k] = v
	end
	return out
end

function M.copy_piles(piles)
	if not piles then
		return { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} }
	end
	local out = {}
	for pile_id, pile in pairs(piles) do
		out[pile_id] = M.copy_pile(pile)
	end
	return out
end

function M.with_piles(state)
	local next = M.shallow_state(state)
	next.piles = M.copy_piles(state.piles)
	return next
end

return M
