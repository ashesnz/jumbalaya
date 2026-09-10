--[[
	word_game package - Jumbalaya domain facade (WORD_GAME).

	Presentation lives on WORD_GAME_UI (`word_game.ui.facade.exports`).
	Game class, G singleton, startup, save, and loop are loaded by app/bootstrap.lua.
]]

local Run = require("word_game.model.run")

return {
	Run = Run,
	RunScope = Run.Scope,
	Busy = require("word_game.model.run.busy"),
	Deck = require("word_game.model.cards.deck"),
	Back = require("word_game.model.cards.deck.back"),
	Round = require("word_game.model.round"),
	Jumble = require("word_game.model.jumble"),
	PlacementWord = require("word_game.model.jumble.placement_word"),
	JumbleRules = require("word_game.model.jumble_play.jumble_rules"),
	Play = require("word_game.model.jumble_play"),
	Board = require("word_game.board"),
	Match = Run.Match,
	InputLock = Run.InputLock,
	Timeline = require("word_game.model.run.timeline"),
	HandSize = require("word_game.model.hand_size"),
	Perks = require("word_game.model.perks"),
	BonusStack = require("word_game.model.jumble.bonus_stack"),
	VoucherDiscard = require("word_game.model.perks.voucher_discard"),
	Persistence = require("word_game.model.persistence"),
}
