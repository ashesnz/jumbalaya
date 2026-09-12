--[[
	word_game/model/jumble_play/opening_deal.lua - Opening deal for jumble stages: populate deck, deal hand, refresh HUD

	Core: none
	Store: game_access.word_round
	Presentation: jumble_hud_refresh (via Jumble.refresh_hud)
]]

local live_game = require("word_game.model.live_game")

local game_access = require("word_game.model.game_access")

local M = {}

function M.deal()
	if not live_game().dealt_letters or not live_game().draw_pile then return end

	local wr = game_access.word_round()
	if WORD_GAME and WORD_GAME.Deck
		and WORD_GAME.Jumble
		and WORD_GAME.Jumble.is_active_hand(wr and wr.set, wr and wr.hand_index) then
		local populate = WORD_GAME.Deck.populate_jumble_deck
		if not populate and WORD_GAME.Deck.populate_jumble then
			populate = WORD_GAME.Deck.populate_jumble
		end
		if populate then populate() end
		if WORD_GAME.Deck.deal_jumble_hand then WORD_GAME.Deck.deal_jumble_hand() end
		if WORD_GAME.Deck.sync_deck_count_display then
			WORD_GAME.Deck.sync_deck_count_display()
		end
		if WORD_GAME.Jumble then
			WORD_GAME.Jumble.refresh_hud()
		end
	end
end

return M
