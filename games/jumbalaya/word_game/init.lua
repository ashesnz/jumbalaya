--[[
	word_game package - Jumbalaya domain facade (WORD_GAME).

	Presentation lives on WORD_GAME_UI (`word_game/ui/facade/exports`).
	Game class, runtime shell, startup, save, and loop are loaded by app/bootstrap.lua.
]]

local Run = require("word_game.model.run")

local M = {
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

function M._bind_store(store)
	M._store = store
end

function M._bind_engine(engine)
	M._engine = engine
end

function M.store()
	return M._store
end

function M.engine()
	return M._engine
end

function M.state()
	local store = M.store()
	if store then
		return store:get()
	end
	return nil
end

return M
