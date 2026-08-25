--[[
	word_game/ui/overlays/ - Pause, settings, win, game over, demo CTA.

	These stay globals (`build_*`, `G.DEFINITIONS.*`) so existing call sites
	do not change. Loaded from app/bootstrap/game_boot.lua.
]]

G.DEFINITIONS = G.DEFINITIONS or {}

require("word_game.ui.overlays.options")
require("word_game.ui.overlays.results")
