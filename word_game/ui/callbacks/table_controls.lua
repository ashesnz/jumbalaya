--[[ word_game/ui/callbacks/table_controls.lua - Table control G.FUNCS registration ]]

local Gameplay = require("word_game.ui.controllers.gameplay")

G.FUNCS.shuffle_hand = Gameplay.shuffle_hand
G.FUNCS.return_placement_cards = Gameplay.return_placement_cards
G.FUNCS.play_placement_word = Gameplay.play_placement_word
G.FUNCS.jumble_next = Gameplay.jumble_next
