--[[
	word_game/ui/overlays/ - Pause, settings, win, game over, demo CTA.

	These stay globals (`build_*`, `game().DEFINITIONS.*`) so existing call sites
	do not change. Loaded from app/bootstrap/game_boot.lua.
]]

local game = require("word_game.ui.util.game_runtime").game

game().DEFINITIONS = game().DEFINITIONS or {}

require("word_game.ui.overlays.options")
require("word_game.ui.overlays.results")
