--[[
	word_game/ui/overlays/ - Pause, settings, win, game over, demo CTA.

	These stay globals (`build_*`, `runtime().DEFINITIONS.*`) so existing call sites
	do not change. Loaded from app/bootstrap/game_boot.lua.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

runtime().DEFINITIONS = runtime().DEFINITIONS or {}

require("word_game.ui.overlays.options")
require("word_game.ui.overlays.results")
