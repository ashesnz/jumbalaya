--[[ packages/jumbalaya_core/jumble/validation.lua - Hand feasibility checks (no G) ]]

local puzzle_spec = require("jumbalaya_core.jumble.puzzle_spec")

local M = {}

local function can_supply(hand_counts, needed)
	for letter, n in pairs(needed or {}) do
		if (hand_counts[letter] or 0) < n then
			return false
		end
	end
	return true
end

function M.letters_needed_from_hand(word, puzzle)
	if not word or not puzzle then return {} end
	puzzle = puzzle_spec.resolve_puzzle(puzzle)
	local needed = {}
	if puzzle.kind == "span" then
		local pre = puzzle.prefix or ""
		local suf = puzzle.suffix or ""
		local center_start, center_finish = puzzle_spec.center_block_range(word, puzzle)
		local center_len = puzzle.center and (center_finish - center_start + 1) or 0
		local middle = word:sub(#pre + 1, #word - #suf)
		if center_len > 0 and center_start then
			local rel = center_start - #pre
			middle = middle:sub(1, rel - 1) .. middle:sub(rel + center_len)
		end
		for i = 1, #middle do
			local ch = middle:sub(i, i)
			needed[ch] = (needed[ch] or 0) + 1
		end
		return needed
	end
	local pattern = puzzle.pattern
	for i = 1, #pattern do
		if pattern:sub(i, i) == "_" then
			local ch = word:sub(i, i)
			needed[ch] = (needed[ch] or 0) + 1
		end
	end
	return needed
end

function M.hand_can_build_word(hand_counts, word, puzzle, opts)
	opts = opts or {}
	if not puzzle_spec.word_fits_pattern(word, puzzle, opts) then return false end
	return can_supply(hand_counts, M.letters_needed_from_hand(word, puzzle))
end

---@param opts table { is_valid_word: fun(word: string): boolean, for_each_word: fun(min_len, max_len, fn): boolean|nil }
function M.has_playable_word(hand_counts, puzzle, opts)
	opts = opts or {}
	if not opts.for_each_word then return false end
	puzzle = puzzle_spec.resolve_puzzle(puzzle)
	if not puzzle then return false end
	local min_len = puzzle.kind == "span" and puzzle.min or #puzzle.pattern
	local max_len = puzzle.kind == "span" and puzzle.max or #puzzle.pattern
	return opts.for_each_word(min_len, max_len, function(word)
		return M.hand_can_build_word(hand_counts, word, puzzle, opts)
	end)
end

---@param opts table { is_word_played: fun(word: string): boolean, is_valid_word: fun(word: string): boolean }
function M.validate_word(slots, puzzle, opts)
	opts = opts or {}
	if not slots or not puzzle then
		return nil, "No puzzle"
	end
	if not require("jumbalaya_core.jumble.slots").all_blanks_filled(slots, puzzle) then
		return nil, "Must play a word or skip entirely"
	end
	local slots_mod = require("jumbalaya_core.jumble.slots")
	local word = slots_mod.build_word(slots, opts.letter_from_card)
	if opts.adjust_word then
		word = opts.adjust_word(word, slots)
	end
	if not word or #word < 3 then
		return nil, "Need a longer word"
	end
	if not puzzle_spec.word_fits_pattern(word, puzzle, opts) then
		return nil, "Does not match"
	end
	local resolved = puzzle_spec.resolve_puzzle(puzzle)
	if resolved and resolved.boss_word then
		if word ~= resolved.boss_word then
			return nil, "Wrong word!"
		end
	elseif not opts.is_valid_word or not opts.is_valid_word(word) then
		return nil, "Not a valid word"
	end
	if opts.is_word_played and opts.is_word_played(word) then
		return nil, "Already played word!"
	end
	return word, nil
end

return M
