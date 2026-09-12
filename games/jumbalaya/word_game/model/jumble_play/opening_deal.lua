--[[
	word_game/model/jumble_play/opening_deal.lua - Opening deal for jumble stages: populate deck, deal hand, refresh HUD

	Core: none
	Store: game_access.word_round
	Presentation: jumble_hud_refresh (via Jumble.refresh_hud)
]]

local live_game = require("word_game.model.live_game")

local game_access = require("word_game.model.game_access")
local Deck = require("word_game.model.cards.deck")
local Jumble = require("word_game.model.jumble")

local M = {}

function M.deal()
	if not live_game().dealt_letters or not live_game().draw_pile then return end

	local wr = game_access.word_round()
	if Jumble.is_active_hand(wr and wr.set, wr and wr.hand_index) then
		local populate = Deck.populate_jumble_deck or Deck.populate_jumble
		if populate then populate() end
		Deck.deal_jumble_hand()
		Deck.sync_deck_count_display()
		Jumble.refresh_hud()
	end
end

return M
