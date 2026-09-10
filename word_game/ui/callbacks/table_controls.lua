--[[ word_game/ui/callbacks/table_controls.lua - Table control G.FUNCS registration ]]

local TableControls = require("word_game.ui.table.controls")

G.FUNCS.shuffle_hand = TableControls.shuffle_hand
G.FUNCS.return_placement_cards = TableControls.return_placement_cards_to_hand
G.FUNCS.play_placement_word = TableControls.play
G.FUNCS.jumble_next = TableControls.jumble_next
