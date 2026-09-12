--[[
	word_game/model/cards/deck/jumble.lua - Jumble deck glue coordinator.

	Core: jumbalaya_core.cards.letter_card
	Store: pile hosts via piles; deck_left_count patches
	Presentation: card_motion_move, hand_shuffle_sync; layout_refresh via LayoutRequest
]]

return function(context)
	local M = context.module

	local function commit_piles(pile_ids)
		if M.commit_pile_hosts then
			M.commit_pile_hosts(pile_ids)
		else
			M.sync_deck_count_display()
		end
	end

	context.commit_piles = commit_piles

	require("word_game.model.cards.deck.jumble_lifecycle")(context)
	require("word_game.model.cards.deck.jumble_deal")(context)
	require("word_game.model.cards.deck.jumble_discard")(context)

	M.deal_boss_hand = require("word_game.model.cards.deck.boss_hand")(M, context)
end
