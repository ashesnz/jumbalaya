--[[ app/bootstrap/presentation_boot.lua - Phase 7 presentation facade boot ]]

local Presentation = require("word_game.model.presentation")

local M = {}

--- Wire Presentation.emit to the engine EventBus.
function M.bind_engine_events(engine)
	if not engine or not engine.events then return end
	Presentation.bind_events(engine.events)
end

function M.install()
	WORD_GAME_UI = require "word_game.ui.facade.exports"
	WORD_GAME_UI.install()
	WORD_GAME.Run.Register(WORD_GAME, WORD_GAME_UI)
	require("word_game.ui.presentation.install").install(WORD_GAME_UI, WORD_GAME)
	require("app.bootstrap.engine_services_boot").install()
	require("word_game.ui.play_effects.hand_clear").install(WORD_GAME.Play)
end

return M
