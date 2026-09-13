--[[
	word_game/model/jumble/validation.lua - Playable-word search, answer cache, ensure_playable_puzzle, validate_current

	Core: jumbalaya_core.jumble.validation
	Store: game_access.word_round
	Presentation: none
]]

local deck_config = require("jumbalaya_core.cards.deck_config")
local BonusStack = require("word_game.model.jumble.bonus_stack")
local live_game = require("word_game.model.live_game")

return function(M)

local round = require("word_game.model.round")
local jumble_rules = require("word_game.model.jumble_play.jumble_rules")
local modifier_effects = require("word_game.model.jumble_play.letter_modifier_effects")
local core = require("jumbalaya_core.jumble.validation")
local core_hand = require("jumbalaya_core.jumble.hand")
local game_access = require("word_game.model.game_access")

local answer_cache = { signature = nil, words = nil }

local function starting_letter_counts()
	local counts = {}
	local letters = deck_config.STARTING_LETTERS or {}
	for _, letter in ipairs(letters) do
		counts[letter] = (counts[letter] or 0) + 1
	end
	return counts
end

local function dictionary_opts()
	return {
		is_valid_word = function(word)
			if not Dictionary then return false end
			Dictionary.load()
			return Dictionary.is_valid(word)
		end,
		for_each_word = function(min_len, max_len, fn)
			if not Dictionary then return false end
			Dictionary.load()
			return Dictionary.for_each_word(min_len, max_len, fn)
		end,
	}
end

M.letters_needed_from_hand = core.letters_needed_from_hand

function M.hand_can_build_word(hand_counts, word, puzzle)
	return core.hand_can_build_word(hand_counts, word, puzzle, dictionary_opts())
end

function M.has_playable_word(hand_counts, puzzle)
	return core.has_playable_word(hand_counts, puzzle, dictionary_opts())
end

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
	local wr = game_access.word_round()
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
	if live_game().dealt_letters and live_game().dealt_letters.cards and #live_game().dealt_letters.cards > 0 and Dictionary then
		return Dictionary.counts_from_cards(live_game().dealt_letters.cards)
	end
	return starting_letter_counts()
end

function M.debug_answer_cards()
	local cards = {}
	if live_game().dealt_letters and live_game().dealt_letters.cards then
		for _, card in ipairs(live_game().dealt_letters.cards) do
			cards[#cards + 1] = card
		end
	end
	local area = live_game().pattern_row and live_game().pattern_row.area
	if area and area.cards then
		for _, card in ipairs(area.cards) do
			cards[#cards + 1] = card
		end
	end
	local bonus_stack = BonusStack
	if bonus_stack and bonus_stack.is_active and bonus_stack.is_active() then
		for _, card in ipairs(bonus_stack.cards() or {}) do
			if card and not card.REMOVED then
				local in_hand = live_game().dealt_letters and card.area == live_game().dealt_letters
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

function M.ensure_playable_puzzle(_wr)
	local ok = false
	game_access.mutate(function(g)
		local wr = g.word_round or _wr
		if not wr then return end
		g.word_round = wr
		local j = wr.jumble
		if not j then return end
		if j.boss_word_active then
			ok = true
			return
		end

		local counts = M.jumble_hand_counts()

		local puzzle = M.resolve_puzzle(j.puzzle)
		if puzzle and M.has_playable_word(counts, puzzle) then
			if puzzle ~= j.puzzle then
				core_hand.apply_puzzle(wr, puzzle, nil)
			end
			ok = true
			return
		end

		local list = M.puzzles(wr.set, wr.hand_index)
		if #list == 0 then return end
		for idx, candidate in ipairs(list) do
			if M.has_playable_word(counts, candidate) then
				j.puzzle_index = idx
				core_hand.apply_puzzle(wr, candidate, nil)
				ok = true
				return
			end
		end
	end)
	return ok
end

function M.validate_current()
	local j = M.state()
	if not j or not j.slots or not j.puzzle then
		return nil, "No puzzle"
	end
	return core.validate_word(j.slots, j.puzzle, {
		letter_from_card = function(card)
			if Dictionary then return Dictionary.letter_from_card(card) end
			return card and card.ability and card.ability.letter
		end,
		adjust_word = function(word, slots)
			local used_cards = jumble_rules.collect_used_cards(slots)
			return modifier_effects.adjust_word_for_q(word, used_cards)
		end,
		is_word_played = function(word) return round.is_word_played(word) end,
		is_valid_word = function(word)
			if not Dictionary then return false end
			Dictionary.load()
			return Dictionary.is_valid(word)
		end,
	})
end
end
