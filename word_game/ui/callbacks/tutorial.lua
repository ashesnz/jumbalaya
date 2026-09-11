--[[ word_game/ui/callbacks/tutorial.lua - Tutorial runtime().FUNCS registration ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local FirstPlayTutorial = require("word_game.ui.tutorial.first_play")
local Funcs = require("bridge.funcs_registry")

Funcs.register("first_play_tutorial_next", FirstPlayTutorial.advance)
