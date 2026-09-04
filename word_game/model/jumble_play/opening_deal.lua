--[[ word_game/model/jumble_play/opening_deal.lua - deals the opening hand for a stage.

	Jumble stages populate the jumble deck instead of the standard letter deck;
	either way the hand ends up dealt and the HUD refreshed.
]]

local M = {}

function M.deal()
	if not G.hand or not G.deck then return end

	local wr = G.GAME and G.GAME.word_round
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
