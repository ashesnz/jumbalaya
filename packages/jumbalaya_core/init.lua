--[[
	jumbalaya_core - Engine-agnostic domain library (Phase 1).

	No Love2D rendering, no global G. Game shell and UI import this package;
	tests can run core rules without mock_env.ensure_engine_globals().
]]

return {
	Store = require("jumbalaya_core.store"),
	Config = require("jumbalaya_core.config"),
	Rules = require("jumbalaya_core.rules"),
	Round = require("jumbalaya_core.round"),
	Jumble = require("jumbalaya_core.jumble"),
	Fixtures = require("jumbalaya_core.fixtures"),
	Dictionary = require("dictionary"),
	DictionaryCards = require("jumbalaya_core.dictionary.cards"),
	CardIdentity = require("jumbalaya_core.cards.identity"),
	CardModifiers = require("jumbalaya_core.cards.letter_modifiers"),
	CardPlayability = require("jumbalaya_core.cards.playability"),
	DeckConfig = require("jumbalaya_core.cards.deck_config"),
	LetterCard = require("jumbalaya_core.cards.letter_card"),
	PileCounts = require("jumbalaya_core.cards.pile_counts"),
	RunState = require("jumbalaya_core.store.run_state"),
	PerkRegistry = require("jumbalaya_core.perks.registry"),
}
