--[[
	jumbalaya-engine - Engine service interfaces and Love2D adapters (Phase 3).
]]

local Renderer = require("jumbalaya-engine.renderer")
local InputService = require("jumbalaya-engine.input")
local AudioService = require("jumbalaya-engine.audio")
local Clock = require("jumbalaya-engine.clock")
local Context = require("jumbalaya-engine.context")
local Adapters = require("jumbalaya-engine.adapters.love2d")
local LetterCardView = require("jumbalaya-engine.views.letter_card_view")
local PileView = require("jumbalaya-engine.views.pile_view")
local SettingsService = require("jumbalaya-engine.settings")
local EventBus = require("jumbalaya-engine.event_bus")
local RetainedUI = require("jumbalaya-engine.retained_ui")
local ViewHost = require("jumbalaya-engine.view_host")

return {
	Renderer = Renderer,
	InputService = InputService,
	AudioService = AudioService,
	Clock = Clock,
	Context = Context,
	EventBus = EventBus,
	Adapters = Adapters,
	SettingsService = SettingsService,
	Views = {
		LetterCardView = LetterCardView,
		PileView = PileView,
	},
	RetainedUI = RetainedUI,
	ViewHost = ViewHost,
}
