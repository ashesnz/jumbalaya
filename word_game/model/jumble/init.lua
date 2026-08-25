--[[ word_game/model/jumble/init.lua - Jumble mode facade ]]

local M = {}

local topology = require("word_game.model.jumble.slot_topology")
for k, v in pairs(topology) do
	M[k] = v
end

require("word_game.model.jumble.puzzle_spec")(M)
require("word_game.model.jumble.validation")(M)
require("word_game.model.jumble.slots")(M)
require("word_game.model.jumble.hand")(M)

return M
