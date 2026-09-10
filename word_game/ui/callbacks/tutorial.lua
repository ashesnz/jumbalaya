--[[ word_game/ui/callbacks/tutorial.lua - Tutorial G.FUNCS registration ]]

local FirstPlayTutorial = require("word_game.ui.tutorial.first_play")

G.FUNCS.first_play_tutorial_next = FirstPlayTutorial.advance
