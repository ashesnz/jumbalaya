--[[
	word_game/board - Jumble pattern row on the TABLE_BOARD felt.

	Public API (WORD_GAME.Board):
	  PlacementTable   session controller — attach to Game as self.placement_table
	  Config             placement row tunables
	  Snap               drag/snap helpers (tests, cardarea)
	  JumbleGeometry     span/fixed row geometry
	  BonusGutter        bonus stack layout and hit tests
]]

return {
	PlacementTable = require "word_game.board.placement.table",
	Config = require "word_game.board.placement.config",
	Snap = require "word_game.board.placement.snap",
	JumbleGeometry = require "word_game.board.jumble.geometry",
	BonusGutter = require "word_game.board.bonus.gutter",
}
