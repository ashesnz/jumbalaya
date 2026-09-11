--[[
	word_game/ui/facade/exports.lua - Presentation facade (WORD_GAME_UI).

	Domain rules stay on WORD_GAME. UI modules and app/devtools/tests that
	need screens, FX, or HUD should use WORD_GAME_UI.
]]

require "word_game.ui.menu"

local WordSidebar = require("word_game.ui.sidebar.init")
local sidebar = WordSidebar()

local M = {
	TableBoard = require("word_game.ui.table.board"),
	Layout = require("word_game.ui.layout"),
	TableDeck = require("word_game.ui.table.deck"),
	VoucherDiscard = require("word_game.ui.perks.discard_bin"),
	SidebarStageButton = require("word_game.ui.sidebar.stage_button"),
	ScoreBanner = require("word_game.ui.score_banner"),
	TimelineTimer = require("word_game.ui.perks.timeline_timer"),
	StageLabel = require("word_game.ui.score_banner.stage_label"),
	TokenReward = require("word_game.ui.table.token_reward"),
	HandClearFocus = require("word_game.ui.tutorial.hand_clear_focus"),
	FirstPlayTutorial = require("word_game.ui.tutorial.first_play"),
	Confetti = require("word_game.ui.feedback.confetti"),
	FloatUpText = require("word_game.ui.feedback.float_up_text"),
	CardInspect = require("word_game.ui.cards.inspect"),
	TableInput = require("word_game.ui.table.input"),
	TradeUI = require("word_game.ui.trade"),
	PerkStamp = require("word_game.ui.perks.stamp"),
	CardFlyOff = require("word_game.ui.play_effects.card_fly_off"),
	EndMatch = require("word_game.ui.overlays.end_match"),
	TableControls = require("word_game.ui.table.controls"),
	HandShuffleAnim = require("word_game.ui.table.controls.shuffle_anim"),
	HandPlacementRecallAnim = require("word_game.ui.table.controls.placement_recall_anim"),
	PlayHoldRedraw = require("word_game.ui.table.controls.play_hold_redraw"),
	PlayEffects = require("word_game.ui.play_effects"),
	BonusStackUI = require("word_game.ui.perks.bonus_stack"),
	BossWordAnnounce = require("word_game.ui.score_banner.boss_announce"),
	Sidebar = sidebar,
}

function M.install()
	sidebar:install()
end

return M
