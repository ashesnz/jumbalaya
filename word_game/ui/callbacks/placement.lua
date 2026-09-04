--[[ word_game/ui/callbacks/placement.lua - Placement play button G.FUNCS ]]

local placement_controls = require("word_game.ui.placement_controls")

G.FUNCS.play_placement_word = function()
	placement_controls.try_play()
end
