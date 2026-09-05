--[[ word_game/model/trade.lua - The Card Marketplace: add or remove a card ]]

local economy = require("word_game.config.economy")
local round_config = require("word_game.config.round_config")
local state = require("word_game.model.state")
local deck = require("word_game.model.cards.deck")
local LetterPalette = require("word_game.config.letter_card_palette")

local M = {}

local TIERS = {
	{ value = 1, letters = { "A", "E", "I", "O", "U", "L", "N", "S", "T", "R" } },
	{ value = 2, letters = { "D", "G" } },
	{ value = 3, letters = { "B", "C", "M", "P" } },
	{ value = 4, letters = { "F", "H", "V", "W", "Y" } },
	{ value = 5, letters = { "K" } },
	{ value = 8, letters = { "J", "X" } },
	{ value = 10, letters = { "Q", "Z" } },
}

M.ACTION_COSTS = {
	add = economy.TRADE_ADD_COST,
	remove = economy.TRADE_REMOVE_COST,
	modifier = economy.TRADE_MODIFIER_COST,
}

local function rand_float(key)
	if type(advance_seed) == "function" and G and G.GAME and G.GAME.seed_streams then
		return advance_seed(key)
	end
	return math.random()
end

local function rand_int(key, min, max)
	if max <= min then return min end
	local n = max - min + 1
	local idx = min + math.floor(rand_float(key) * n)
	if idx > max then idx = max end
	return idx
end

local function copy_letters(letters)
	local out = {}
	for i, letter in ipairs(letters) do
		out[i] = letter
	end
	return out
end

function M.item_in_deck(item)
	return item and item.card and not item.card.REMOVED and true or false
end

function M.sync_offer_cards(offer_table)
	if not offer_table then return end
	local lists = {}
	if offer_table.add and offer_table.add.letters then
		lists[#lists + 1] = offer_table.add.letters
	end
	if offer_table.remove and offer_table.remove.letters then
		lists[#lists + 1] = offer_table.remove.letters
	end
	for _, letters in ipairs(lists) do
		for _, item in ipairs(letters) do
			if item and item.letter then
				item.card = deck.find_deck_card(item.letter)
			end
		end
	end
end

function M.can_use()
	local rs = state.get()
	return rs and not rs.trade_used_this_hand
end

function M.is_showdown_market()
	local wr = G.GAME and G.GAME.word_round
	return wr and round_config.is_showdown(wr.hand_index, wr.set) and true or false
end

local function make_market_item(letter)
	local item = {
		mode = "market",
		letter = letter,
		color = LetterPalette.DEFAULT_FACE_COLOR,
	}
	item.card = deck.find_deck_card(letter)
	return item
end

local function roll_add_offer()
	local tiers = TIERS
	local count = economy.TRADE_IN or 2
	local eligible = {}
	for i, tier in ipairs(tiers) do
		if #(tier.letters) >= 1 then
			eligible[#eligible + 1] = i
		end
	end
	local row = eligible[rand_int("market_row", 1, #eligible)]
	local tier = tiers[row]
	local pool = copy_letters(tier.letters)
	local picks = {}
	for i = 1, count do
		local idx = rand_int("market_letter", 1, #pool)
		local letter = pool[idx]
		if #pool > 1 then
			table.remove(pool, idx)
		end
		picks[#picks + 1] = make_market_item(letter)
	end
	return {
		mode = "add",
		row = row,
		value = tier.value,
		pool = tier.letters,
		letters = picks,
	}
end

local function roll_remove_offer()
	local count = economy.TRADE_IN or 2
	local pool = deck.list_deck_cards()
	if #pool < 1 then
		return nil
	end
	local picks = {}
	local n = math.min(count, #pool)
	for _ = 1, n do
		local idx = rand_int("market_remove", 1, #pool)
		local card = table.remove(pool, idx)
		picks[#picks + 1] = {
			mode = "remove",
			card = card,
			letter = deck.card_letter(card),
			color = deck.color_from_card(card),
			ap = card.base and card.base.letter_index or 0,
		}
	end
	return {
		mode = "remove",
		letters = picks,
	}
end

--- Three distinct cards: one vowel plus two random A–Z letters (no duplicates).
function M.roll_offer()
	local picks = {}
	local used = {}

	local function take_unique(key, roll_fn)
		for attempt = 1, 52 do
			local letter = roll_fn(key .. "_" .. attempt)
			if letter and not used[letter] then
				used[letter] = true
				return letter
			end
		end
		for i = 1, 26 do
			local letter = string.char(string.byte("A") + i - 1)
			if not used[letter] then
				used[letter] = true
				return letter
			end
		end
	end

	picks[#picks + 1] = make_market_item(take_unique("market_vowel", deck.random_vowel_letter))
	for i = 1, 2 do
		picks[#picks + 1] = make_market_item(take_unique("market_letter_" .. i, deck.random_letter))
	end

	return {
		add = { mode = "market", letters = picks },
		remove = nil,
		showdown = false,
	}
end

function M.add_letter(item, opts)
	local rs = state.get()
	if not rs then return false, "No match" end
	if not item or not item.letter then return false, "No letter selected" end
	local cost = (opts and opts.cost) or M.ACTION_COSTS.add
	if not state.spend_tokens(cost) then return false, "Not enough tokens" end
	local card = deck.draft_letter(item.letter, item.color)
	item.card = card
	if opts and opts.modifier then
		deck.apply_to_card(card)
	end
	if not (opts and opts.defer_used) then
		rs.trade_used_this_hand = true
	end
	return true, card
end

function M.remove_card(item, opts)
	local rs = state.get()
	if not rs then return false, "No match" end
	local target = item and (item.card or item.remove_card)
	if not target or target.REMOVED then
		return false, "No card selected"
	end
	local cost = (opts and opts.cost) or M.ACTION_COSTS.remove
	if not state.spend_tokens(cost) then return false, "Not enough tokens" end
	deck.destroy_card(target)
	item.card = nil
	if not (opts and opts.defer_used) then
		rs.trade_used_this_hand = true
	end
	return true
end

function M.apply(item, opts)
	if not item then return false, "No card selected" end
	local action = (opts and opts.action) or item.action or item.mode or "add"
	if action == "remove" then
		if not M.item_in_deck(item) then
			return false, "Card not in deck"
		end
		return M.remove_card(item, opts)
	end
	if action == "modifier" then
		if not M.item_in_deck(item) then
			return false, "Card not in deck"
		end
		if not item.card or deck.is_modified(item.card) then
			return false, "Card is already modified"
		end
		if not state.spend_tokens(M.ACTION_COSTS.modifier) then return false, "Not enough tokens" end
		deck.apply_to_card(item.card)
		return true, item.card
	end
	return M.add_letter(item, { cost = (opts and opts.cost) or M.ACTION_COSTS.add, defer_used = opts and opts.defer_used })
end

function M.mark_used()
	local rs = state.get()
	if rs then
		rs.trade_used_this_hand = true
	end
end

return M
