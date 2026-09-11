--[[ word_game/ui/callbacks/table_controls.lua - Table control runtime().FUNCS registration ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Gameplay = require("word_game.ui.controllers.gameplay")

runtime().FUNCS.shuffle_hand = Gameplay.shuffle_hand
runtime().FUNCS.return_placement_cards = Gameplay.return_placement_cards
runtime().FUNCS.play_placement_word = Gameplay.play_placement_word
runtime().FUNCS.jumble_next = Gameplay.jumble_next
