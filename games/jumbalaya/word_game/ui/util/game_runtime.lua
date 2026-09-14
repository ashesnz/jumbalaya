--[[
	word_game/ui/util/game_runtime.lua - UI access to the live Game instance.

	Live game is bound at boot; call sites use the function reference:

	Prefer: local runtime = require("word_game.ui.util.game_runtime").game
	  runtime()

	When a function already takes the live shell as a parameter named `game`,
	use a different name for the accessor (`runtime`) to avoid shadowing.

	Do not re-wrap in `local function runtime()` — that hides the shell in every file.
	See packages/jumbalaya-engine/README.md for the engine-side cycle.
]]

local BridgeRuntime = require("app.runtime")

local M = {}

function M.game()
	return BridgeRuntime.game()
end

return M
