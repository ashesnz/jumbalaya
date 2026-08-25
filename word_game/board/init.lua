--[[
	word_game/board - Jumble pattern row on the TABLE_BOARD felt.

	Public API (WORD_GAME.Board):
	  PlacementTable  session controller — attach to Game as self.placement_table
	  Config            tunable constants
]]

return {
	PlacementTable = require "word_game.board.placement_table",
	Config = require "word_game.board.config",
}
