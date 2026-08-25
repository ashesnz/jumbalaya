--[[
	word_game package - Jumbalaya domain facade.

	Structure:
	  config/  - static tables (AP, vault, perks, upgrades)
	  model/   - match rules (scoring, vault, round, trade)
	  ui/      - TABLE_BOARD presentation and overlays

	Game class, G singleton, startup, save, and loop are loaded by app/bootstrap.lua.
]]

require "word_game.ui.menu"

local WordSidebar = require("word_game.ui.sidebar")
local sidebar = WordSidebar()

local M = {
	Deck = require("word_game.model.cards.deck"),
	Back = require("word_game.model.cards.deck.back"),
	Round = require("word_game.model.round"),
	Jumble = require("word_game.model.jumble"),
	Play = require("word_game.model.play"),
	Board = require("word_game.board"),
	TableBoard = require("word_game.ui.table_board"),
	Layout = require("word_game.ui.layout"),
	TableDeck = require("word_game.ui.table_deck"),
	LetterOverlay = require("word_game.ui.letter_overlay"),
	ScoreBanner = require("word_game.ui.score_banner"),
	TimelineTimer = require("word_game.ui.timeline_timer"),
	TokenReward = require("word_game.ui.token_reward"),
	HandClearFocus = require("word_game.ui.hand_clear_focus"),
	Confetti = require("word_game.ui.confetti"),
	FloatUpText = require("word_game.ui.float_up_text"),
	CardInspect = require("word_game.ui.card_inspect"),
	CardHover = require("word_game.ui.card_hover"),
	PlayerPortrait = require("word_game.ui.player_portrait"),
	AllyHost = require("word_game.ui.ally_host"),
	GuestHost = require("word_game.ui.guest_host"),
	PlayerHost = require("word_game.ui.player_host"),
	TradeUI = require("word_game.ui.trade"),
	PerkMarketplace = require("word_game.ui.perk_market"),
	EndMatch = require("word_game.ui.end_match"),
	HandShuffle = require("word_game.ui.hand_shuffle"),
	PlayHoldRedraw = require("word_game.ui.play_hold_redraw"),
	PlayEffects = require("word_game.ui.play_effects"),
	Sidebar = sidebar,
}

sidebar:install()

return M
