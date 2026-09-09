--[[ word_game/ui/callbacks/placement.lua - Placement play button G.FUNCS ]]

local placement = require("word_game.ui.table.controls.placement")

G.FUNCS.play_placement_word = function()
	placement.try_play()
end
