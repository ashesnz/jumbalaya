--[[
	word_game/model/trade/init.lua - Card Marketplace offers, token spend add/remove/modifier, trade_used tracking

	Core: jumbalaya_core.config.gameplay.economy, jumbalaya_core.config.gameplay.round, jumbalaya_core.config.gameplay.letter_tiers
	Store: store_ops.dispatch(RUN_STATE_MARK_TRADE_USED), run.state tokens
	Presentation: none
]]

local economy = require("jumbalaya_core.config.gameplay.economy")
local state = require("word_game.model.run.state")
local game_access = require("word_game.model.game_access")
local deck = require("word_game.model.cards.deck")
local store_ops = require("word_game.model.store_ops")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")
local Random = require("jumbalaya-engine.util.random")

local M = {}

M.ACTION_COSTS = {
	add = economy.TRADE_ADD_COST,
	remove = economy.TRADE_REMOVE_COST,
	modifier = economy.TRADE_MODIFIER_COST,
}

local function game_state()
	return game_access.get()
end

local function mark_trade_used()
	local store = store_ops.store()
	if store then
		store_ops.dispatch(store, { type = "RUN_STATE_MARK_TRADE_USED" })
	else
		local rs = state.get()
		if rs then rs.trade_used_this_hand = true end
	end
end

local function rand_float(key)
	local game = game_state()
	if game and game.seed_streams then
		return Random.advance_seed(key)
	end
	return math.random()
end

function M.item_in_deck(item)
	return item and item.card and not item.card.REMOVED and true or false
end

function M.can_add(item)
	return item and item.letter and true or false
end

function M.can_remove(item)
	return M.item_in_deck(item)
end

function M.can_modify(item)
	if not M.item_in_deck(item) then return false end
	return item.card and not deck.is_modified(item.card)
end

function M.can_afford(cost)
	local rs = state.get()
	if not rs then return false end
	return (rs.tokens or 0) >= (cost or 0)
end

function M.sync_offer_cards(offer_table)
	local letters = offer_table and offer_table.add and offer_table.add.letters
	if not letters then return end
	for _, item in ipairs(letters) do
		if item and item.letter then
			item.card = deck.find_deck_card(item.letter)
		end
	end
end

function M.can_use()
	local rs = state.get()
	return rs and not rs.trade_used_this_hand
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
		picks[#picks + 1] = make_market_item(take_unique("market_consonant_" .. i, deck.random_consonant_letter))
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
		mark_trade_used()
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
		mark_trade_used()
	end
	return true
end

function M.apply(item, opts)
	if not item then return false, "No card selected" end
	local action = (opts and opts.action) or item.action or item.mode or "add"
	if action == "remove" or action == "modifier" then
		if item.letter then
			item.card = deck.find_deck_card(item.letter)
		end
	end
	if action == "remove" then
		if not M.can_remove(item) then
			return false, "Card not in deck"
		end
		if not M.can_afford(M.ACTION_COSTS.remove) then
			return false, "Not enough tokens"
		end
		return M.remove_card(item, opts)
	end
	if action == "modifier" then
		if not M.can_modify(item) then
			if M.item_in_deck(item) and item.card and deck.is_modified(item.card) then
				return false, "Card is already modified"
			end
			return false, "Card not in deck"
		end
		if not state.spend_tokens(M.ACTION_COSTS.modifier) then return false, "Not enough tokens" end
		deck.apply_to_card(item.card)
		mark_trade_used()
		return true, item.card
	end
	if not M.can_add(item) then return false, "No letter selected" end
	if not M.can_afford(M.ACTION_COSTS.add) then return false, "Not enough tokens" end
	return M.add_letter(item, { cost = (opts and opts.cost) or M.ACTION_COSTS.add, defer_used = opts and opts.defer_used })
end

function M.mark_used()
	mark_trade_used()
end

return M
