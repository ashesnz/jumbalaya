--[[
	word_game/ui/player_host.lua - Player portrait speech host compatibility facade.

	The implementation lives in focused modules under word_game/ui/player_host/.
	This module retains the original require path and PlayerHost public API.
]]

local Context = require("word_game.ui.player_host.context")
local PlayerHost = EaseNode:derive("PlayerHost")
local context = Context.new(PlayerHost)

require("word_game.ui.player_host.core")(context)
require("word_game.ui.player_host.spotlight")(context)
require("word_game.ui.player_host.stage3")(context)
require("word_game.ui.player_host.stage3_party")(context)
require("word_game.ui.player_host.marco")(context)
require("word_game.ui.player_host.tutorial")(context)

return PlayerHost
