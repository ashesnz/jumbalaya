--[[ word_game/ui/presentation/install.lua - Register model→UI presentation hooks at boot ]]

local GameRT = require("word_game.ui.util.game_runtime")
local Presentation = require("word_game.model.presentation")
local CardFocus = require("jumbalaya-engine.interaction.card_focus")
local TableAreas = require("word_game.model.table_areas")
local Funcs = require("app.callbacks.funcs")
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local backgrounds = require("word_game.ui.layout.backgrounds")

local handlers = {
	require("word_game.ui.presentation.handlers.layout"),
	require("word_game.ui.presentation.handlers.sidebar"),
	require("word_game.ui.presentation.handlers.score_banner"),
	require("word_game.ui.presentation.handlers.timeline"),
	require("word_game.ui.presentation.handlers.play"),
	require("word_game.ui.presentation.handlers.table"),
}

local M = {}

function M.install(ui, domain)
	Presentation.clear()
	ui = ui or rawget(_G, "WORD_GAME_UI") or {}
	domain = domain or rawget(_G, "WORD_GAME") or {}

	local ctx = {
		ui = ui,
		domain = domain,
		Presentation = Presentation,
		Funcs = Funcs,
		Scheduler = Scheduler,
		backgrounds = backgrounds,
		runtime = function() return GameRT.game() end,
	}

	CardFocus.install({
		hand_area = TableAreas.dealt_letters,
		bonus_stack_contains = function(node)
			return ui.BonusStackUI and ui.BonusStackUI.contains(node)
		end,
	})

	for _, handler in ipairs(handlers) do
		handler.register(Presentation, ctx)
	end
end

return M
