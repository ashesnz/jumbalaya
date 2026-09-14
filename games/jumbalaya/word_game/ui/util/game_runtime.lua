--[[
	word_game/ui/util/game_runtime.lua - UI access to the live Game instance.

	Live game is bound at boot; call sites use the function reference:

	  local game = require("word_game.ui.util.game_runtime").game
	  local g = game()

	Do not re-wrap in `local function runtime()` — that hides the shell in every file.
	See packages/jumbalaya-engine/README.md for the engine-side cycle.
]]

local BridgeRuntime = require("app.runtime")

local M = {}

function M.game()
	return BridgeRuntime.game()
end

return M
