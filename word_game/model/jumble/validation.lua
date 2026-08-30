--[[ word_game/model/jumble/validation.lua - Dictionary and hand feasibility checks ]]

return function(M)

local function starting_letter_counts()
	local counts = {}
	local letters = (WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.STARTING_LETTERS) or {}
	for _, letter in ipairs(letters) do
		counts[letter] = (counts[letter] or 0) + 1
	end
	return counts
end

local function can_supply(hand_counts, needed)
	for letter, n in pairs(needed or {}) do
		if (hand_counts[letter] or 0) < n then
			return false
		end
	end
	return true
end

local function can_supply_with_u_substitute(hand_counts, needed)
	if can_supply(hand_counts, needed) then return true end
	local deck = require("word_game.model.cards.deck")
	if not deck.deck_has_modified_letter("U") then return false end
	for _, vowel in ipairs({ "A", "E", "I", "O", "U" }) do
		local deficit = (needed[vowel] or 0) - (hand_counts[vowel] or 0)
		if deficit == 1 then
			local adjusted = {}
			for letter, n in pairs(needed) do
				adjusted[letter] = n
			end
			adjusted[vowel] = adjusted[vowel] - 1
			if can_supply(hand_counts, adjusted) then
				return true
			end
		end
	end
	return false
end

--- Letter multiset the hand must supply (fixed/anchor letters are free).
function M.letters_needed_from_hand(word, puzzle)
	if not word or not puzzle then return {} end
	puzzle = M.resolve_puzzle(puzzle)
	local needed = {}
	if puzzle.kind == "span" then
		local pre = puzzle.prefix or ""
		local suf = puzzle.suffix or ""
		local center_start, center_finish = M.center_block_range(word, puzzle)
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

function M.hand_can_build_word(hand_counts, word, puzzle)
	if not M.word_fits_pattern(word, puzzle) then return false end
	return can_supply_with_u_substitute(hand_counts, M.letters_needed_from_hand(word, puzzle))
end

function M.has_playable_word(hand_counts, puzzle)
	puzzle = M.resolve_puzzle(puzzle)
	if not puzzle or not Dictionary then return false end
	Dictionary.load()
	local min_len = puzzle.kind == "span" and puzzle.min or #puzzle.pattern
	local max_len = puzzle.kind == "span" and puzzle.max or #puzzle.pattern
	return Dictionary.for_each_word(min_len, max_len, function(word)
		return M.hand_can_build_word(hand_counts, word, puzzle)
	end)
end

-- The playable-word sweep walks the whole dictionary, so the debug overlay
-- must not trigger it every frame. Results are memoized on a cheap signature:
-- hand multiset + puzzle identity + how many words have been played.
local answer_cache = {signature = nil, words = nil}

local function answer_signature(hand_counts, puzzle, limit)
	local parts = {
		"limit:" .. tostring(limit),
		"puzzle:" .. tostring(puzzle),
		"kind:" .. (puzzle.kind or ""),
		"pattern:" .. (puzzle.pattern or ""),
		"prefix:" .. (puzzle.prefix or ""),
		"suffix:" .. (puzzle.suffix or ""),
		"center:" .. (puzzle.center or ""),
	}
	for letter, count in pairs(hand_counts or {}) do
		parts[#parts + 1] = letter .. ":" .. count
	end
	local wr = G.GAME and G.GAME.word_round
	local played = wr and wr.played_words
	local played_count = 0
	if played then
		for _ in pairs(played) do
			played_count = played_count + 1
		end
	end
	parts[#parts + 1] = "played:" .. played_count
	table.sort(parts)
	return table.concat(parts, "|")
end

function M.invalidate_answer_cache()
	answer_cache.signature = nil
	answer_cache.words = nil
end

function M.find_playable_words(hand_counts, puzzle, limit)
	puzzle = M.resolve_puzzle(puzzle)
	if not puzzle or not Dictionary then return {} end

	local signature = answer_signature(hand_counts, puzzle, limit)
	if answer_cache.signature == signature then
		return answer_cache.words
	end

	Dictionary.load()
	local round = require("word_game.model.round")
	local found = {}
	local min_len = puzzle.kind == "span" and puzzle.min or #puzzle.pattern
	local max_len = puzzle.kind == "span" and puzzle.max or #puzzle.pattern
	Dictionary.for_each_word(min_len, max_len, function(word)
		if not round.is_word_played(word) and M.hand_can_build_word(hand_counts, word, puzzle) then
			found[#found + 1] = word
			if limit and #found >= limit then return true end
		end
	end)
	table.sort(found)

	answer_cache.signature = signature
	answer_cache.words = found
	return found
end

function M.jumble_hand_counts()
	if G.hand and G.hand.cards and #G.hand.cards > 0 and Dictionary then
		return Dictionary.counts_from_cards(G.hand.cards)
	end
	return starting_letter_counts()
end

function M.debug_answer_cards()
	local cards = {}
	if G.hand and G.hand.cards then
		for _, card in ipairs(G.hand.cards) do
			cards[#cards + 1] = card
		end
	end
	local area = G.placement_table and G.placement_table.area
	if area and area.cards then
		for _, card in ipairs(area.cards) do
			cards[#cards + 1] = card
		end
	end
	local bonus_stack = WORD_GAME and WORD_GAME.BossWordStack
	if bonus_stack and bonus_stack.is_active and bonus_stack.is_active() then
		for _, card in ipairs(bonus_stack.cards() or {}) do
			if card and not card.REMOVED then
				local in_hand = G.hand and card.area == G.hand
				local in_placement = area and card.area == area
				if not in_hand and not in_placement then
					cards[#cards + 1] = card
				end
			end
		end
	end
	return cards
end

function M.debug_answer_counts()
	if not Dictionary then return {} end
	return Dictionary.counts_from_cards(M.debug_answer_cards())
end

function M.ensure_playable_puzzle(wr)
	wr = wr or (G.GAME and G.GAME.word_round)
	local j = wr and wr.jumble
	if not j then return false end
	if j.boss_word_active then return true end

	local counts = M.jumble_hand_counts()

	local puzzle = M.resolve_puzzle(j.puzzle)
	if puzzle and M.has_playable_word(counts, puzzle) then
		if puzzle ~= j.puzzle then
			M.apply_puzzle(wr, puzzle)
		end
		return true
	end

	local wr = G.GAME and G.GAME.word_round
	local list = M.puzzles(wr and wr.set, wr and wr.hand_index)
	if #list == 0 then return false end
	for idx, candidate in ipairs(list) do
		if M.has_playable_word(counts, candidate) then
			j.puzzle_index = idx
			M.apply_puzzle(wr, candidate)
			return true
		end
	end
	return false
end

function M.validate_current()
	local j = M.state()
	if not j or not j.slots or not j.puzzle then
		return nil, "No puzzle"
	end
	if not M.all_blanks_filled(j.slots, j.puzzle) then
		return nil, "Must play a word or skip entirely"
	end
	local used_cards = {}
	for _, slot in ipairs(j.slots or {}) do
		if slot.kind == "blank" and slot.card then
			used_cards[#used_cards + 1] = slot.card
		elseif slot.kind == "span" then
			for _, card in ipairs(slot.cards or {}) do
				used_cards[#used_cards + 1] = card
			end
		end
	end
	local word = M.build_word(j.slots)
	local modifier_effects = require("word_game.model.play.letter_modifier_effects")
	word = modifier_effects.adjust_word_for_q(word, used_cards)
	if not word or #word < 3 then
		return nil, "Need a longer word"
	end
	if not M.word_fits_pattern(word, j.puzzle) then
		return nil, "Does not match"
	end
	if j.puzzle and j.puzzle.boss_word then
		if word ~= j.puzzle.boss_word then
			return nil, "Wrong word!"
		end
	elseif not Dictionary or not Dictionary.is_valid(word) then
		return nil, "Not a valid word"
	end
	local round = require("word_game.model.round")
	if round.is_word_played(word) then
		return nil, "Already played word!"
	end
	return word, nil
end
end
