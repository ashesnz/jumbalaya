--[[
	word_game package - Jumbalaya domain facade.

	Structure:
	  config/  - static tables (perks, economy, puzzles)
	  model/   - match rules (scoring, round, trade)
	  ui/      - TABLE_BOARD presentation and overlays

	Game class, G singleton, startup, save, and loop are loaded by app/bootstrap.lua.
]]

require "word_game.ui.menu"

local WordSidebar = require("word_game.ui.sidebar")
local sidebar = WordSidebar()
local RunScope = require("word_game.model.run_scope")

local M = {
	RunScope = RunScope,
	Deck = require("word_game.model.cards.deck"),
	Back = require("word_game.model.cards.deck.back"),
	Round = require("word_game.model.round"),
	Jumble = require("word_game.model.jumble"),
	Play = require("word_game.model.jumble_play"),
	Board = require("word_game.board"),
	TableBoard = require("word_game.ui.table_board"),
	Layout = require("word_game.ui.layout"),
	TableDeck = require("word_game.ui.table_deck"),
	Match = require("word_game.model.match"),
	InputLock = require("word_game.model.input_lock"),
	HandSize = require("word_game.config.hand_size"),
	TableDiscard = require("word_game.ui.perks.discard_bin"),
	VaultStageButton = require("word_game.ui.vault_stage_button"),
	ScoreBanner = require("word_game.ui.score_banner"),
	TimelineTimer = require("word_game.ui.perks.timeline_timer"),
	StageLabel = require("word_game.ui.stage_label"),
	TokenReward = require("word_game.ui.token_reward"),
	HandClearFocus = require("word_game.ui.hand_clear_focus"),
	Confetti = require("word_game.ui.confetti"),
	FloatUpText = require("word_game.ui.float_up_text"),
	CardInspect = require("word_game.ui.card_inspect"),
	PlayerPortrait = require("word_game.ui.player_portrait"),
	AllyHost = require("word_game.ui.ally_host"),
	GuestHost = require("word_game.ui.guest_host"),
	PlayerHost = require("word_game.ui.player_host"),
	TradeUI = require("word_game.ui.trade"),
	PerkStamp = require("word_game.ui.perks.stamp"),
	Perks = require("word_game.model.perks"),
	CardFlyOff = require("word_game.ui.card_fly_off"),
	EndMatch = require("word_game.ui.end_match"),
	HandShuffle = require("word_game.ui.hand_shuffle"),
	HandShuffleAnim = require("word_game.ui.hand_shuffle.shuffle_anim"),
	HandPlacementRecallAnim = require("word_game.ui.hand_shuffle.placement_recall_anim"),
	PlayHoldRedraw = require("word_game.ui.play_hold_redraw"),
	PlayEffects = require("word_game.ui.play_effects"),
	BonusStack = require("word_game.model.bonus_stack"),
	BossWordStack = require("word_game.ui.boss_word_stack"),
	BossWordAnnounce = require("word_game.ui.boss_word_announce"),
	Sidebar = sidebar,
}

sidebar:install()

require("word_game.model.run_scope_register")(M)

return M
