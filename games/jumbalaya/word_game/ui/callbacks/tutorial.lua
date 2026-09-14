--[[ word_game/ui/callbacks/tutorial.lua - Tutorial game().FUNCS registration ]]

local game = require("word_game.ui.util.game_runtime").game

local FirstPlayTutorial = require("word_game.ui.tutorial.first_play")
local Funcs = require("app.callbacks.funcs")

Funcs.register("first_play_tutorial_next", FirstPlayTutorial.advance)
