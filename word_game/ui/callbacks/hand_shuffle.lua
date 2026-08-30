--[[ word_game/ui/callbacks/hand_shuffle.lua - Hand shuffle and jumble advance G.FUNCS ]]

local HandShuffle = require("word_game.ui.hand_shuffle")

G.FUNCS.shuffle_hand = function()
	HandShuffle.shuffle_hand()
end

G.FUNCS.return_placement_cards = function()
	HandShuffle.return_placement_cards_to_hand()
end

G.FUNCS.jumble_next = function()
	if WORD_GAME and WORD_GAME.Play then
		WORD_GAME.Play.jumble_next()
	end
	HandShuffle.sync()
end
