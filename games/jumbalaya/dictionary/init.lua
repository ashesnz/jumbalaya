--[[
	dictionary package - offline English word validation and hand queries.

	Assets are prebuilt by _tools/build_wordlist.py:
	  dictionary/words_set.lua       O(1) exact word lookup (~40k words)
	  resources/dictionary/wordlist.txt  plain-text source list (uppercase)

	The prefix trie is built once in memory on Dictionary.load() from words_set.
	(~40k words; typically well under 100ms on desktop)

	Public API:
	  Dictionary.load()
	  Dictionary.is_valid(word)
	  Dictionary.is_prefix_valid(prefix, hand_counts)
	  Dictionary.find_playable(hand_counts)
	  Dictionary.has_playable_word(hand_counts)
	  Dictionary.can_play_from_cards(cards)
	  Dictionary.counts_from_cards(cards)
	  Dictionary.word_from_cards(cards)
	  Dictionary.letter_from_card(card)
	  Dictionary.validate_cards(cards)
]]

local Dictionary = {}
local card_helpers = require("jumbalaya_core.dictionary.cards")

local loaded = false
local words_set
local trie_root
local signature_set = {}

local MIN_LEN = 3
local MAX_LEN = 8

Dictionary.letter_from_card = card_helpers.letter_from_card
Dictionary.color_from_card = card_helpers.color_from_card

local function trie_insert(word)
	local node = trie_root
	for i = 1, #word do
		local ch = word:sub(i, i)
		local children = node.c
		if not children then
			children = {}
			node.c = children
		end
		local child = children[ch]
		if not child then
			child = {}
			children[ch] = child
		end
		node = child
	end
	node.w = true
end

local function word_signature(word)
	local chars = {}
	for i = 1, #word do
		chars[i] = word:sub(i, i)
	end
	table.sort(chars)
	return table.concat(chars)
end

local function build_signature_index()
	signature_set = {}
	for word in pairs(words_set) do
		local len = #word
		if len >= MIN_LEN and len <= MAX_LEN then
			signature_set[word_signature(word)] = true
		end
	end
end

local function build_trie()
	trie_root = {}
	for word in pairs(words_set) do
		trie_insert(word)
	end
end

function Dictionary.load()
	if loaded then return end
	words_set = require("dictionary.words_set")
	build_trie()
	build_signature_index()
	loaded = true
end

local function normalize(word)
	if not word then return nil end
	return string.upper(word)
end

function Dictionary.is_valid(word)
	if not loaded then Dictionary.load() end
	word = normalize(word)
	if not word or #word < MIN_LEN or #word > MAX_LEN then return false end
	return words_set[word] == true
end

Dictionary.counts_from_cards = card_helpers.counts_from_cards
Dictionary.word_from_cards = card_helpers.word_from_cards

local function copy_counts(counts)
	local out = {}
	for k, v in pairs(counts) do
		out[k] = v
	end
	return out
end

function Dictionary.is_prefix_valid(prefix, hand_counts)
	if not loaded then Dictionary.load() end
	prefix = normalize(prefix)
	if not prefix then return true end

	local node = trie_root
	for i = 1, #prefix do
		local ch = prefix:sub(i, i)
		local children = node.c
		if not children or not children[ch] then
			return false
		end
		node = children[ch]
	end
	return true
end

--- Enumerate dictionary words buildable from `hand_counts`.
--- @param hand_counts table<string, number> letter -> available count
--- @param limit number|nil stop after this many words (for debug hints)
--- @return string[] words sorted alphabetically when fully enumerated
--- Iterate dictionary words in a length range; return true from `fn` to stop early.
function Dictionary.for_each_word(min_len, max_len, fn)
	if not loaded then Dictionary.load() end
	min_len = min_len or MIN_LEN
	max_len = max_len or MAX_LEN
	for word in pairs(words_set) do
		local len = #word
		if len >= min_len and len <= max_len then
			if fn(word) then return true end
		end
	end
	return false
end

function Dictionary.find_playable(hand_counts, limit)
	if not loaded then Dictionary.load() end

	local found = {}
	local remaining = copy_counts(hand_counts or {})

	local function dfs(node, path)
		if limit and #found >= limit then return end
		if node.w and #path >= MIN_LEN and #path <= MAX_LEN then
			found[#found + 1] = path
			if limit and #found >= limit then return end
		end
		if #path >= MAX_LEN then return end
		local children = node.c
		if not children then return end
		local letters = {}
		for letter in pairs(children) do
			letters[#letters + 1] = letter
		end
		table.sort(letters)
		for _, letter in ipairs(letters) do
			if limit and #found >= limit then return end
			local child = children[letter]
			local n = remaining[letter] or 0
			if n > 0 then
				remaining[letter] = n - 1
				dfs(child, path .. letter)
				remaining[letter] = n
			end
		end
	end

	dfs(trie_root, "")
	if not limit or #found < limit then
		table.sort(found)
	end
	return found
end

function Dictionary.validate_cards(cards)
	local word = Dictionary.word_from_cards(cards)
	if #word < MIN_LEN or #word > MAX_LEN then
		return false, word
	end
	return Dictionary.is_valid(word), word
end

--- True if any 3–7 letter subset of `hand_counts` spells a dictionary word.
--- Uses a multiset signature index built at load time.
--- @param hand_counts table<string, number> letter -> available count
function Dictionary.has_playable_word(hand_counts)
	if not loaded then Dictionary.load() end

	local letters = {}
	for letter, n in pairs(hand_counts or {}) do
		for _ = 1, n do
			letters[#letters + 1] = letter
		end
	end

	local n = #letters
	if n < MIN_LEN then return false end

	local max_mask = bit.lshift(1, n) - 1
	for mask = 1, max_mask do
		local size = 0
		local chars = {}
		for i = 1, n do
			if bit.band(mask, bit.lshift(1, i - 1)) ~= 0 then
				size = size + 1
				chars[size] = letters[i]
			end
		end
		if size >= MIN_LEN and size <= MAX_LEN then
			table.sort(chars)
			if signature_set[table.concat(chars)] then
				return true
			end
		end
	end
	return false
end

--- @param cards table[]
function Dictionary.can_play_from_cards(cards)
	return Dictionary.has_playable_word(Dictionary.counts_from_cards(cards))
end

Dictionary.is_vowel_letter = card_helpers.is_vowel_letter
Dictionary.hand_has_vowel = card_helpers.hand_has_vowel

return Dictionary
