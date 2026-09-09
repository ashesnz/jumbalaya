--[[
	word_game package - Jumbalaya domain facade.

	Structure:
	  config/  - static tables (perks, economy, puzzles)
	  model/   - match rules (scoring, round, trade)
	  ui/      - TABLE_BOARD presentation and overlays

	Game class, G singleton, startup, save, and loop are loaded by app/bootstrap.lua.
]]

require "word_game.ui.menu"

local WordSidebar = require("word_game.ui.sidebar.init")
local sidebar = WordSidebar()
local RunScope = require("word_game.model.run.scope")

local M = {
	RunScope = RunScope,
	Deck = require("word_game.model.cards.deck"),
	Back = require("word_game.model.cards.deck.back"),
	Round = require("word_game.model.round"),
	Jumble = require("word_game.model.jumble"),
	Play = require("word_game.model.jumble_play"),
	Board = require("word_game.board"),
	TableBoard = require("word_game.ui.table.board"),
	Layout = require("word_game.ui.layout"),
	TableDeck = require("word_game.ui.table.deck"),
	Match = require("word_game.model.run.match"),
	InputLock = require("word_game.model.run.input_lock"),
	HandSize = require("word_game.config.hand_size"),
	VoucherDiscard = require("word_game.ui.perks.discard_bin"),
	SidebarStageButton = require("word_game.ui.sidebar.stage_button"),
	ScoreBanner = require("word_game.ui.score_banner"),
	TimelineTimer = require("word_game.ui.perks.timeline_timer"),
	StageLabel = require("word_game.ui.table.stage_label"),
	TokenReward = require("word_game.ui.table.token_reward"),
	HandClearFocus = require("word_game.ui.tutorial.hand_clear_focus"),
	FirstPlayTutorial = require("word_game.ui.tutorial.first_play"),
	Confetti = require("word_game.ui.feedback.confetti"),
	FloatUpText = require("word_game.ui.feedback.float_up_text"),
	CardInspect = require("word_game.ui.cards.inspect"),
	TableInput = require("word_game.ui.table.input"),
	TradeUI = require("word_game.ui.trade"),
	PerkStamp = require("word_game.ui.perks.stamp"),
	Perks = require("word_game.model.perks"),
	CardFlyOff = require("word_game.ui.play_effects.card_fly_off"),
	EndMatch = require("word_game.ui.overlays.end_match"),
	HandShuffle = require("word_game.ui.hand_shuffle"),
	HandShuffleAnim = require("word_game.ui.hand_shuffle.shuffle_anim"),
	HandPlacementRecallAnim = require("word_game.ui.hand_shuffle.placement_recall_anim"),
	PlayHoldRedraw = require("word_game.ui.hand_shuffle.play_hold_redraw"),
	PlayEffects = require("word_game.ui.play_effects"),
	BonusStack = require("word_game.model.jumble.bonus_stack"),
	BossWordStack = require("word_game.ui.boss_word_stack"),
	BossWordAnnounce = require("word_game.ui.score_banner.boss_announce"),
	Sidebar = sidebar,
}

sidebar:install()

require("word_game.model.run.register")(M)

return M
