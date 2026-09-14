--[[
	word_game/model/cards/deck/jumble.lua - Jumble deck glue coordinator.

	Core: jumbalaya_core.cards.letter_card
	Store: pile hosts via piles; deck_left_count patches
	Presentation: card_motion_move, hand_shuffle_sync; layout_refresh via LayoutRequest
]]

local Shared = require("word_game.model.cards.deck.shared")
local function Deck()
	return package.loaded["word_game.model.cards.deck"]
end


local M = {}

local function commit_piles(pile_ids)
	if Deck().commit_pile_hosts then
		Deck().commit_pile_hosts(pile_ids)
	else
		Deck().sync_deck_count_display()
	end
end

Shared.commit_piles = commit_piles

local jumble_lifecycle = require("word_game.model.cards.deck.jumble_lifecycle")
for k, v in pairs(jumble_lifecycle) do
	M[k] = v
end
local jumble_deal = require("word_game.model.cards.deck.jumble_deal")
for k, v in pairs(jumble_deal) do
	M[k] = v
end
local jumble_discard = require("word_game.model.cards.deck.jumble_discard")
for k, v in pairs(jumble_discard) do
	M[k] = v
end

local boss_hand = require("word_game.model.cards.deck.boss_hand")
M.deal_boss_hand = boss_hand.deal_boss_hand

return M
