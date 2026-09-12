--[[
	word_game/model/jumble/init.lua - Jumble mode facade (topology, BonusStack, PlacementWord, hand glue)

	Core: jumbalaya_core.jumble.*, jumbalaya_core.rules.bonus_stack (via submodules)
	Store: game_access.word_round via hand glue
	Presentation: puzzle_applied, score_banner_jumble_hand_start, boss_puzzle_revealed, boss_word_begin, jumble_hud_refresh (via hand glue)
]]

local M = {}

local topology = require("word_game.model.jumble.slot_topology")
for k, v in pairs(topology) do
	M[k] = v
end

M.BonusStack = require("word_game.model.jumble.bonus_stack")
M.PlacementWord = require("word_game.model.jumble.placement_word")
M.return_bonus_card = require("word_game.model.jumble.bonus_return").return_card

require("word_game.model.jumble.puzzle_spec")(M)
require("word_game.model.jumble.validation")(M)
require("word_game.model.jumble.slots")(M)
require("word_game.model.jumble.hand")(M)

return M
