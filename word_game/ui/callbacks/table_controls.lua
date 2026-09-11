--[[ word_game/ui/callbacks/table_controls.lua - Table control G.FUNCS registration ]]

local TableControls = require("word_game.ui.table.controls")
local store_sync = require("bridge.store_sync")

G.FUNCS.shuffle_hand = function(e)
	if G._store then
		store_sync.dispatch(G._store, { type = "SHUFFLE_HAND" })
	end
	TableControls.shuffle_hand(e)
end

G.FUNCS.return_placement_cards = function(e)
	if G._store then
		store_sync.dispatch(G._store, { type = "RETURN_PLACEMENT_CARDS" })
	end
	TableControls.return_placement_cards_to_hand(e)
end

G.FUNCS.play_placement_word = function(e)
	if G._store then
		store_sync.dispatch(G._store, { type = "PLAY_WORD" })
	end
	TableControls.play(e)
end

G.FUNCS.jumble_next = function(e)
	if G._store then
		store_sync.dispatch(G._store, { type = "JUMBLE_NEXT" })
	end
	TableControls.jumble_next(e)
end
