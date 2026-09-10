--[[ word_game/ui/callbacks/table_controls.lua - Table control G.FUNCS (shuffle, placement recall, jumble advance) ]]

local TableControls = require("word_game.ui.table.controls")

G.FUNCS.shuffle_hand = function()
	TableControls.shuffle_hand()
end

G.FUNCS.return_placement_cards = function()
	TableControls.return_placement_cards_to_hand()
end

G.FUNCS.jumble_next = function()
	if WORD_GAME and WORD_GAME.Play then
		WORD_GAME.Play.jumble_next()
	end
	TableControls.sync()
end
