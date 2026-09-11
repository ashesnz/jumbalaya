--[[ word_game/ui/callbacks/table_controls.lua - Table control FUNCS registration ]]

local Gameplay = require("word_game.ui.controllers.gameplay")
local Funcs = require("bridge.funcs_registry")

Funcs.register("shuffle_hand", Gameplay.shuffle_hand)
Funcs.register("return_placement_cards", Gameplay.return_placement_cards)
Funcs.register("play_placement_word", Gameplay.play_placement_word)
Funcs.register("jumble_next", Gameplay.jumble_next)
